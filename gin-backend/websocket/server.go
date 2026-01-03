package websocket

import (
	"encoding/json"
	"errors"
	"flux-panel/utils"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// 消息类型
const (
	MessageTypeAddLimiters    = "AddLimiters"
	MessageTypeUpdateLimiters = "UpdateLimiters"
	MessageTypeDeleteLimiters = "DeleteLimiters"
	MessageTypeAddService     = "AddService"
	MessageTypeUpdateService  = "UpdateService"
	MessageTypeDeleteService  = "DeleteService"
	MessageTypePauseService   = "PauseService"
	MessageTypeResumeService  = "ResumeService"
	MessageTypeAddChains      = "AddChains"
	MessageTypeUpdateChains   = "UpdateChains"
	MessageTypeDeleteChains   = "DeleteChains"
)

// Message WebSocket 消息结构
type Message struct {
	Type string      `json:"type"`
	Data interface{} `json:"data"`
	ID   string      `json:"requestId,omitempty"`
}

// Response 响应结构
type Response struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}

// NodeConnection 节点连接
type NodeConnection struct {
	NodeID     uint
	Secret     string
	Conn       *websocket.Conn
	Send       chan []byte
	Done       chan struct{}
	mutex      sync.Mutex
	pendingReq map[string]chan *Response
	reqMutex   sync.Mutex
}

// UserConnection 用户连接
type UserConnection struct {
	Conn *websocket.Conn
	Send chan []byte
}

// Server WebSocket 服务端
type Server struct {
	connections     map[uint]*NodeConnection
	userConnections map[*UserConnection]bool
	mutex           sync.RWMutex
	userMutex       sync.RWMutex
	upgrader        websocket.Upgrader
}

var (
	instance *Server
	once     sync.Once
)

// GetServer 获取 WebSocket 服务端单例
func GetServer() *Server {
	once.Do(func() {
		instance = &Server{
			connections:     make(map[uint]*NodeConnection),
			userConnections: make(map[*UserConnection]bool),
			upgrader: websocket.Upgrader{
				ReadBufferSize:  1024,
				WriteBufferSize: 1024,
				CheckOrigin:     func(r *http.Request) bool { return true },
			},
		}
	})
	return instance
}

// AddConnection 添加节点连接
func (s *Server) AddConnection(nodeID uint, secret string, conn *websocket.Conn) *NodeConnection {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	// 关闭旧连接
	if old, exists := s.connections[nodeID]; exists {
		close(old.Done)
		old.Conn.Close()
	}

	nc := &NodeConnection{
		NodeID:     nodeID,
		Secret:     secret,
		Conn:       conn,
		Send:       make(chan []byte, 256),
		Done:       make(chan struct{}),
		pendingReq: make(map[string]chan *Response),
	}

	s.connections[nodeID] = nc

	// 启动读写协程
	go nc.readPump()
	go nc.writePump()

	log.Printf("节点 %d 已连接", nodeID)
	return nc
}

// RemoveConnection 移除节点连接
func (s *Server) RemoveConnection(nodeID uint) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	if nc, exists := s.connections[nodeID]; exists {
		close(nc.Done)
		nc.Conn.Close()
		delete(s.connections, nodeID)
		log.Printf("节点 %d 已断开", nodeID)
	}
}

// GetConnection 获取节点连接
func (s *Server) GetConnection(nodeID uint) *NodeConnection {
	s.mutex.RLock()
	defer s.mutex.RUnlock()
	return s.connections[nodeID]
}

// SendMessage 发送消息到节点
func (s *Server) SendMessage(nodeID uint, data interface{}, msgType string) (*Response, error) {
	nc := s.GetConnection(nodeID)
	if nc == nil {
		return nil, errors.New("节点未连接")
	}

	return nc.SendMessage(data, msgType)
}

// AddUserConnection 添加用户连接
func (s *Server) AddUserConnection(conn *websocket.Conn) *UserConnection {
	s.userMutex.Lock()
	defer s.userMutex.Unlock()

	uc := &UserConnection{
		Conn: conn,
		Send: make(chan []byte, 256),
	}

	s.userConnections[uc] = true

	go uc.writePump()

	return uc
}

// RemoveUserConnection 移除用户连接
func (s *Server) RemoveUserConnection(uc *UserConnection) {
	s.userMutex.Lock()
	defer s.userMutex.Unlock()

	if _, ok := s.userConnections[uc]; ok {
		delete(s.userConnections, uc)
		close(uc.Send)
		uc.Conn.Close()
	}
}

// BroadcastToUsers 广播消息给所有用户
func (s *Server) BroadcastToUsers(message []byte) {
	s.userMutex.RLock()
	defer s.userMutex.RUnlock()

	for uc := range s.userConnections {
		select {
		case uc.Send <- message:
		default:
			close(uc.Send)
			delete(s.userConnections, uc)
		}
	}
}

// SendMessage 发送消息并等待响应
func (nc *NodeConnection) SendMessage(data interface{}, msgType string) (*Response, error) {
	// 生成消息 ID
	msgID := generateMsgID()

	msg := Message{
		Type: msgType,
		Data: data,
		ID:   msgID,
	}

	msgBytes, err := json.Marshal(msg)
	if err != nil {
		return nil, err
	}

	// 创建响应通道
	respChan := make(chan *Response, 1)
	nc.reqMutex.Lock()
	nc.pendingReq[msgID] = respChan
	nc.reqMutex.Unlock()

	// 发送消息
	select {
	case nc.Send <- msgBytes:
	case <-nc.Done:
		return nil, errors.New("连接已关闭")
	case <-time.After(5 * time.Second):
		return nil, errors.New("发送超时")
	}

	// 等待响应
	select {
	case resp := <-respChan:
		return resp, nil
	case <-nc.Done:
		return nil, errors.New("连接已关闭")
	case <-time.After(30 * time.Second):
		nc.reqMutex.Lock()
		delete(nc.pendingReq, msgID)
		nc.reqMutex.Unlock()
		return nil, errors.New("响应超时")
	}
}

// readPump 读取消息
func (nc *NodeConnection) readPump() {
	defer func() {
		GetServer().RemoveConnection(nc.NodeID)
	}()

	nc.Conn.SetReadLimit(512 * 1024)
	nc.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	nc.Conn.SetPongHandler(func(string) error {
		nc.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := nc.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("节点 %d 读取错误: %v", nc.NodeID, err)
			}
			return
		}

		// 尝试解密
		var encMsg struct {
			Encrypted bool   `json:"encrypted"`
			Data      string `json:"data"`
		}

		if err := json.Unmarshal(message, &encMsg); err == nil && encMsg.Encrypted && encMsg.Data != "" {
			crypto, err := utils.GetOrCreateCrypto(nc.Secret)
			if err == nil {
				decrypted, err := crypto.DecryptString(encMsg.Data)
				if err == nil {
					message = []byte(decrypted)
				} else {
					log.Printf("节点 %d 解密失败: %v", nc.NodeID, err)
				}
			}
		}

		// 检查系统信息 ACK
		if strings.Contains(string(message), "memory_usage") {
			ackMsg := map[string]string{"type": "call"}
			ackBytes, _ := json.Marshal(ackMsg)
			if nc.Secret != "" {
				// 发送加密的 ACK
				crypto, _ := utils.GetOrCreateCrypto(nc.Secret)
				if crypto != nil {
					enc, _ := crypto.EncryptString(string(ackBytes))
					ackBytes, _ = json.Marshal(map[string]interface{}{
						"encrypted": true,
						"data":      enc,
						"timestamp": time.Now().Unix(),
					})
				}
			}

			select {
			case nc.Send <- ackBytes:
			default:
				log.Printf("节点 %d 发送通道已满，丢弃 ACK", nc.NodeID)
			}
		}

		// 尝试解析为响应格式
		var resp struct {
			ID      string      `json:"requestId"`
			Success bool        `json:"success"`
			Message string      `json:"message"`
			Data    interface{} `json:"data"`
			Type    string      `json:"type"` // 添加 Type 字段以便识别
		}

		if err := json.Unmarshal(message, &resp); err != nil {
			// 如果不是 JSON，或者是其他格式，尝试作为系统信息处理
			// log.Printf("节点 %d 解析消息失败: %v", nc.NodeID, err)
			// continue
		}

		// 检查是否为对 Panel 请求的响应
		if resp.ID != "" {
			nc.reqMutex.Lock()
			if respChan, exists := nc.pendingReq[resp.ID]; exists {
				delete(nc.pendingReq, resp.ID)
				nc.reqMutex.Unlock()

				respChan <- &Response{
					Success: resp.Success,
					Message: resp.Message,
					Data:    resp.Data,
				}
				continue // 已处理为响应，跳过广播
			}
			nc.reqMutex.Unlock()
		}

		// 如果不是响应，或者没有 ID，则视为推送消息，广播给用户
		// 对于 Agent 上报的系统信息，通常 Type='info'
		// 我们需要补充 NodeID，以便前端知道是哪个节点的消息
		broadcastMsg := map[string]interface{}{
			"id":   nc.NodeID,
			"type": resp.Type,
			"data": resp.Data,
		}

		// 如果 Type 为空，可能是旧版 Agent 或其他格式，默认为 info
		// 对于系统信息，Spring Boot 逻辑是把整个 message作为data
		if broadcastMsg["type"] == "" {
			broadcastMsg["type"] = "info"
			// 尝试解析 message 为 map
			var rawData interface{}
			if err := json.Unmarshal(message, &rawData); err == nil {
				broadcastMsg["data"] = rawData
			} else {
				// 无法解析，可能就不是系统信息
				continue
			}
		}

		msgBytes, err := json.Marshal(broadcastMsg)
		if err == nil {
			GetServer().BroadcastToUsers(msgBytes)
		}
	}
}

// writePump 写入消息
func (nc *NodeConnection) writePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		nc.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-nc.Send:
			nc.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				nc.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			nc.mutex.Lock()
			err := nc.Conn.WriteMessage(websocket.TextMessage, message)
			nc.mutex.Unlock()

			if err != nil {
				log.Printf("节点 %d 写入错误: %v", nc.NodeID, err)
				return
			}

		case <-ticker.C:
			nc.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := nc.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}

		case <-nc.Done:
			return
		}
	}
}

// 生成消息 ID
var msgCounter uint64
var msgMutex sync.Mutex

func generateMsgID() string {
	msgMutex.Lock()
	defer msgMutex.Unlock()
	msgCounter++
	return time.Now().Format("20060102150405") + "_" + string(rune(msgCounter))
}

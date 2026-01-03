package websocket

import (
	"time"

	"github.com/gorilla/websocket"
)

// writePump 写入消息 (用户连接)
func (uc *UserConnection) writePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		uc.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-uc.Send:
			uc.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				uc.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			if err := uc.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		case <-ticker.C:
			uc.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := uc.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// readPump 读取消息 (用户连接) - 主要用于处理 Close 和 Ping/Pong
func (uc *UserConnection) readPump() {
	defer func() {
		GetServer().RemoveUserConnection(uc)
		uc.Conn.Close()
	}()

	uc.Conn.SetReadLimit(512 * 1024)
	uc.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	uc.Conn.SetPongHandler(func(string) error {
		uc.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		if _, _, err := uc.Conn.ReadMessage(); err != nil {
			break
		}
	}
}

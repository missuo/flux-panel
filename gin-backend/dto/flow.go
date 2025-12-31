package dto

// FlowDto 流量上报数据
type FlowDto struct {
	N string `json:"n"` // 服务名称 (格式: forwardId_userId_userTunnelId)
	U int64  `json:"u"` // 上传流量
	D int64  `json:"d"` // 下载流量
}

// GostConfigDto Gost配置数据
type GostConfigDto struct {
	Limiters []ConfigItem `json:"limiters"`
	Chains   []ConfigItem `json:"chains"`
	Services []ConfigItem `json:"services"`
}

// ConfigItem 配置项
type ConfigItem struct {
	Name string `json:"name"`
}

// EncryptedMessage 加密消息
type EncryptedMessage struct {
	Encrypted bool   `json:"encrypted"`
	Data      string `json:"data"`
}

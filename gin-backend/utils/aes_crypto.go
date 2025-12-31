package utils

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"sync"
)

const (
	gcmIVLength  = 12 // GCM 推荐的 IV 长度
	gcmTagLength = 16 // GCM 认证标签长度
)

// AESCrypto AES-256-GCM 加密器
type AESCrypto struct {
	key []byte
}

// 加密器缓存
var (
	cryptoCache = make(map[string]*AESCrypto)
	cacheMutex  sync.RWMutex
)

// NewAESCrypto 创建新的 AES 加密器
// secret: 密钥字符串，将通过 SHA-256 派生为 32 字节密钥
func NewAESCrypto(secret string) (*AESCrypto, error) {
	if secret == "" {
		return nil, errors.New("密钥不能为空")
	}

	// SHA-256 密钥派生 (32 字节 = 256 位)
	hash := sha256.Sum256([]byte(secret))

	return &AESCrypto{
		key: hash[:],
	}, nil
}

// GetOrCreateCrypto 获取或创建加密器实例（带缓存）
func GetOrCreateCrypto(secret string) (*AESCrypto, error) {
	if secret == "" {
		return nil, errors.New("密钥不能为空")
	}

	// 先尝试读取缓存
	cacheMutex.RLock()
	if crypto, exists := cryptoCache[secret]; exists {
		cacheMutex.RUnlock()
		return crypto, nil
	}
	cacheMutex.RUnlock()

	// 创建新实例并缓存
	cacheMutex.Lock()
	defer cacheMutex.Unlock()

	// 双重检查
	if crypto, exists := cryptoCache[secret]; exists {
		return crypto, nil
	}

	crypto, err := NewAESCrypto(secret)
	if err != nil {
		return nil, err
	}

	cryptoCache[secret] = crypto
	return crypto, nil
}

// Encrypt 加密数据
// 返回: Base64(IV + ciphertext)
func (c *AESCrypto) Encrypt(plaintext []byte) (string, error) {
	if len(plaintext) == 0 {
		return "", errors.New("待加密数据不能为空")
	}

	block, err := aes.NewCipher(c.key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	// 生成随机 IV
	iv := make([]byte, gcmIVLength)
	if _, err := rand.Read(iv); err != nil {
		return "", err
	}

	// 加密数据
	ciphertext := gcm.Seal(nil, iv, plaintext, nil)

	// 组合 IV + 密文
	result := make([]byte, len(iv)+len(ciphertext))
	copy(result[:len(iv)], iv)
	copy(result[len(iv):], ciphertext)

	// Base64 编码
	return base64.StdEncoding.EncodeToString(result), nil
}

// EncryptString 加密字符串
func (c *AESCrypto) EncryptString(plaintext string) (string, error) {
	return c.Encrypt([]byte(plaintext))
}

// Decrypt 解密数据
// encryptedData: Base64(IV + ciphertext)
func (c *AESCrypto) Decrypt(encryptedData string) ([]byte, error) {
	if encryptedData == "" {
		return nil, errors.New("加密数据不能为空")
	}

	// Base64 解码
	encrypted, err := base64.StdEncoding.DecodeString(encryptedData)
	if err != nil {
		return nil, errors.New("Base64 解码失败: " + err.Error())
	}

	if len(encrypted) < gcmIVLength {
		return nil, errors.New("加密数据长度不足")
	}

	block, err := aes.NewCipher(c.key)
	if err != nil {
		return nil, err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}

	// 分离 IV 和密文
	iv := encrypted[:gcmIVLength]
	ciphertext := encrypted[gcmIVLength:]

	// 解密
	plaintext, err := gcm.Open(nil, iv, ciphertext, nil)
	if err != nil {
		return nil, errors.New("解密失败: " + err.Error())
	}

	return plaintext, nil
}

// DecryptString 解密为字符串
func (c *AESCrypto) DecryptString(encryptedData string) (string, error) {
	plaintext, err := c.Decrypt(encryptedData)
	if err != nil {
		return "", err
	}
	return string(plaintext), nil
}

// ClearCryptoCache 清除指定密钥的缓存
func ClearCryptoCache(secret string) {
	cacheMutex.Lock()
	defer cacheMutex.Unlock()
	delete(cryptoCache, secret)
}

// ClearAllCryptoCache 清除所有缓存
func ClearAllCryptoCache() {
	cacheMutex.Lock()
	defer cacheMutex.Unlock()
	cryptoCache = make(map[string]*AESCrypto)
}

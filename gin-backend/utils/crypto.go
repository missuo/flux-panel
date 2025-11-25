package utils

import (
	"crypto/md5"
	"encoding/hex"
)

// MD5 计算MD5哈希
func MD5(str string) string {
	hash := md5.Sum([]byte(str))
	return hex.EncodeToString(hash[:])
}

// HashPassword 哈希密码
func HashPassword(password string) string {
	return MD5(password)
}

// ComparePassword 比较密码
func ComparePassword(hashedPassword, password string) bool {
	return hashedPassword == MD5(password)
}

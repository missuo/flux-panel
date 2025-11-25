package utils

import (
	"flux-panel/config"
	"flux-panel/models"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Claims JWT自定义声明
type Claims struct {
	UserID int    `json:"sub"`
	User   string `json:"user"`
	Name   string `json:"name"`
	RoleID int    `json:"role_id"`
	jwt.RegisteredClaims
}

// GenerateToken 生成JWT Token
func GenerateToken(user *models.User) (string, error) {
	expireTime := time.Now().Add(time.Hour * time.Duration(config.AppConfig.JWT.ExpireTime))

	claims := &Claims{
		UserID: int(user.ID),
		User:   user.User,
		Name:   user.User,
		RoleID: user.RoleID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expireTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(config.AppConfig.JWT.Secret))
}

// ParseToken 解析JWT Token
func ParseToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(config.AppConfig.JWT.Secret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, fmt.Errorf("invalid token")
}

// ValidateToken 验证Token是否有效
func ValidateToken(tokenString string) bool {
	_, err := ParseToken(tokenString)
	return err == nil
}

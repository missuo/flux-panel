package config

import (
	"fmt"
	"os"

	"github.com/spf13/viper"
)

// Config 应用配置结构
type Config struct {
	Server   ServerConfig   `mapstructure:"server"`
	Database DatabaseConfig `mapstructure:"database"`
	JWT      JWTConfig      `mapstructure:"jwt"`
	Captcha  CaptchaConfig  `mapstructure:"captcha"`
	Log      LogConfig      `mapstructure:"log"`
}

// ServerConfig 服务器配置
type ServerConfig struct {
	Port           string `mapstructure:"port"`
	Mode           string `mapstructure:"mode"`
	MaxConnections int    `mapstructure:"max_connections"`
	ShutdownTimeout int   `mapstructure:"shutdown_timeout"`
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	Host            string `mapstructure:"host"`
	Port            int    `mapstructure:"port"`
	User            string `mapstructure:"user"`
	Password        string `mapstructure:"password"`
	DBName          string `mapstructure:"dbname"`
	MaxOpenConns    int    `mapstructure:"max_open_conns"`
	MaxIdleConns    int    `mapstructure:"max_idle_conns"`
	ConnMaxLifetime int    `mapstructure:"conn_max_lifetime"`
}

// JWTConfig JWT配置
type JWTConfig struct {
	Secret     string `mapstructure:"secret"`
	ExpireTime int64  `mapstructure:"expire_time"` // 小时
}

// CaptchaConfig 验证码配置
type CaptchaConfig struct {
	Enabled bool  `mapstructure:"enabled"`
	Expire  int64 `mapstructure:"expire"` // 秒
}

// LogConfig 日志配置
type LogConfig struct {
	Dir   string `mapstructure:"dir"`
	Level string `mapstructure:"level"`
}

var AppConfig *Config

// InitConfig 初始化配置
func InitConfig() error {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")

	// 设置环境变量
	viper.AutomaticEnv()

	// 设置默认值
	setDefaults()

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			fmt.Println("Config file not found, using defaults and environment variables")
		} else {
			return fmt.Errorf("error reading config file: %w", err)
		}
	}

	// 从环境变量覆盖配置
	overrideFromEnv()

	AppConfig = &Config{}
	if err := viper.Unmarshal(AppConfig); err != nil {
		return fmt.Errorf("unable to decode into config struct: %w", err)
	}

	return nil
}

// setDefaults 设置默认值
func setDefaults() {
	viper.SetDefault("server.port", "6365")
	viper.SetDefault("server.mode", "debug")
	viper.SetDefault("server.max_connections", 2000)
	viper.SetDefault("server.shutdown_timeout", 30)

	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", 3306)
	viper.SetDefault("database.max_open_conns", 20)
	viper.SetDefault("database.max_idle_conns", 5)
	viper.SetDefault("database.conn_max_lifetime", 500)

	viper.SetDefault("jwt.expire_time", 2160) // 90天 (90 * 24小时)

	viper.SetDefault("captcha.enabled", true)
	viper.SetDefault("captcha.expire", 120)

	viper.SetDefault("log.dir", "./logs")
	viper.SetDefault("log.level", "info")
}

// overrideFromEnv 从环境变量覆盖配置
func overrideFromEnv() {
	if host := os.Getenv("DB_HOST"); host != "" {
		viper.Set("database.host", host)
	}
	if user := os.Getenv("DB_USER"); user != "" {
		viper.Set("database.user", user)
	}
	if password := os.Getenv("DB_PASSWORD"); password != "" {
		viper.Set("database.password", password)
	}
	if dbname := os.Getenv("DB_NAME"); dbname != "" {
		viper.Set("database.dbname", dbname)
	}
	if secret := os.Getenv("JWT_SECRET"); secret != "" {
		viper.Set("jwt.secret", secret)
	}
	if logDir := os.Getenv("LOG_DIR"); logDir != "" {
		viper.Set("log.dir", logDir)
	}
}

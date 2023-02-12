return {
    SERVER_DEFAULT_WEIGHT = 1, -- 服务器默认权重
    SERVER_DOWN_TIME = 2, -- 服务器心跳超时下线间隔(单位:秒)
    WAIT_SOCKET_EXPIRE_TIME = 60, -- socket连接不发包超时时间(单位:秒)
    SAVE_DATA_TIME = 5 * 60, -- 保存数据时间(单位:秒)
    SAVE_DATA_TIME_TEST = 15 * 60, -- 测试环境保存数据时间(单位:秒)
    ROLE_SAVE_DATA_TIME = 30, -- 玩家自身数据变化保存数据时间(单位:秒)
    BACKUP_DAYS = 21, -- 备份天数(n天之前备份)
    WAIT_LOGIN_EXPIRE_TIME = 60 -- 登录失败踢出时间(单位:秒) 
}

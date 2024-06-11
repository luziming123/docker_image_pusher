#!/bin/bash

# 登录 Docker 注册服务器
# 本段脚本用于使用环境变量 ALIYUN_REGISTRY_USER 和 ALIYUN_REGISTRY_PASSWORD 登录 Docker 注册服务器，
# 以便后续进行镜像的拉取、打标签及推送操作。
echo "正在登录 Docker 注册服务器..."
if ! docker login -u "$ALIYUN_REGISTRY_USER" -p "$ALIYUN_REGISTRY_PASSWORD" "$ALIYUN_REGISTRY"; then
    echo "登录 Docker 注册服务器失败。退出程序。"
    exit 1
fi

# 处理镜像
# 此循环从 images.txt 文件中逐行读取，针对每一行指定的镜像执行拉取、重新打标签以及推送到阿里云容器注册服务器的操作。
while IFS= read -r line; do
    # 跳过空行和注释行
    # 判断当前行是否为空或以 '#' 开头，若是则跳过，不进行后续处理。
    [[ -z $line || $line =~ ^# ]] && continue

    # 提取镜像名称，忽略注释内容
    # 从当前行中提取镜像名称，去除行末可能出现的注释内容，并通过awk命令获取最后一个路径分隔符后的部分作为镜像标签。
    image_name=${line%%'#'*}
    image_name_tag=$(echo $image_name | awk -F'/' '{print $NF}')
    new_image="$ALIYUN_REGISTRY/$ALIYUN_NAME_SPACE/$image_name_tag"

    echo "正在处理镜像: $image_name -> $new_image"
    if ! docker pull "$image_name"; then
        echo "拉取镜像 $image_name 失败。跳过打标签与推送操作。"
        continue
    fi

    if ! docker tag "$image_name" "$new_image"; then
        echo "为镜像 $image_name 打上标签 $new_image 失败。跳过推送操作。"
        continue
    fi

    if ! docker push "$new_image"; then
        echo "推送镜像 $new_image 失败。"
        continue
    fi
done < images.txt

echo "所有镜像处理完成。"
#!/bin/bash

# Log in to Docker registry
echo "Logging in to Docker registry..."
if ! docker login -u "$ALIYUN_REGISTRY_USER" -p "$ALIYUN_REGISTRY_PASSWORD" "$ALIYUN_REGISTRY"; then
    echo "Failed to log in to Docker registry. Exiting."
    exit 1
fi

# Process images
while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z $line || $line =~ ^# ]] && continue

    # Extract the image name, ignoring comments
    image_name=${line%%'#'*}
    image_name_tag=$(echo $image_name | awk -F'/' '{print $NF}')
    new_image="$ALIYUN_REGISTRY/$ALIYUN_NAME_SPACE/$image_name_tag"

    echo "Processing image: $image_name -> $new_image"
    if ! docker pull "$image_name"; then
        echo "Failed to pull image $image_name. Skipping tag and push operations."
        continue
    fi

    if ! docker tag "$image_name" "$new_image"; then
        echo "Failed to tag image $image_name as $new_image. Skipping push operation."
        continue
    fi

    if ! docker push "$new_image"; then
        echo "Failed to push image $new_image."
        continue
    fi
done < images.txt

echo "All images processed successfully."
#!/bin/bash

# Function to retrieve user data from Vine API
get_vine_user_data() {
    local user_id_str=$1
    local url="https://archive.vine.co/profiles/_/${user_id_str}.json"
    local response=$(curl -s "$url")

    if [[ $response == *"\"status\":200"* ]]; then
        echo "$response"
    else
        echo "Error: Could not retrieve user data." >&2
        exit 1
    fi
}

# Function to retrieve user information from Vine API
get_vine_user_info() {
    local vanity=$1
    local url=""
    local response=""

    if [[ $vanity =~ ^[0-9]+$ ]]; then
        url="https://archive.vine.co/profiles/_/${vanity}.json"
    else
        url="https://vine.co/api/users/profiles/vanity/${vanity}"
    fi

    response=$(curl -s "$url")

    if [[ $response == *"\"status\":200"* ]]; then
        echo "$response"
    else
        echo "Error: Could not retrieve user information." >&2
        exit 1
    fi
}

# Function to collect post IDs from user profile data
collect_post_ids() {
    local profile_data="$1"
    echo "$profile_data" | grep -o '"postId": *"[^"]*"' | sed 's/"postId": *"\([^"]*\)"/\1/'
}

# Function to download post data
download_post_data() {
    local post_id="$1"
    local user_folder="$2"
    local url="https://archive.vine.co/posts/${post_id}.json"
    local response=$(curl -s "$url")

    if [[ $response == *"\"status\":200"* ]]; then
        local post_folder="${user_folder}/post_${post_id}"
        mkdir -p "$post_folder" || { echo "Error: Could not create folder for post $post_id." >&2; exit 1; }

        local thumbnail_url=$(echo "$response" | grep -o '"thumbnailUrl": *"[^"]*"' | sed 's/"thumbnailUrl": *"\([^"]*\)"/\1/')
        local video_url=$(echo "$response" | grep -E -o '"videoLowURL": *"[^"]*"' | sed 's/"videoLowURL": *"\([^"]*\)"/\1/')

        curl -s "$thumbnail_url" -o "${post_folder}/${post_id}_thumbnail.jpg" || { echo "Error: Could not download thumbnail for post $post_id." >&2; exit 1; }

        if [[ ! -z "$video_url" ]]; then
            curl -s "$video_url" -o "${post_folder}/${post_id}_video.mp4" || { echo "Error: Could not download video for post $post_id." >&2; exit 1; }
        fi
    else
        echo "Error: Could not retrieve data for post $post_id." >&2
        exit 1
    fi
}

# Main script starts here
read -p "Enter a Vine vanity or user ID: " vanity
vanitydata=$(get_vine_user_info "$vanity")

if [[ $vanitydata == *"\"status\":200"* ]]; then
    username=$(echo "$vanitydata" | grep -o '"username": *"[^"]*"' | sed 's/"username": *"\([^"]*\)"/\1/')
    user_folder="./$username"
    mkdir -p "$user_folder" || { echo "Error: Could not create folder for user $username." >&2; exit 1; }

    post_ids=$(collect_post_ids "$vanitydata")

    if [[ -z "$post_ids" ]]; then
        echo "No posts found for the user."
    else
        echo "Collected $(echo "$post_ids" | wc -w) post IDs: $post_ids"
        read -p "Do you want to download data for each post? (yes/no): " download_choice

        if [[ "$download_choice" == "yes" ]]; then
            mkdir -p "${user_folder}/posts"
            for post_id in $post_ids; do
                download_post_data "$post_id" "$user_folder"
            done
        else
            echo "Skipping post data download."
        fi
    fi
else
    echo "Error: Could not retrieve user information."
    exit 1
fi

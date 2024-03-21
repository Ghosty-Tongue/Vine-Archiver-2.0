#!/bin/bash

# Function to retrieve user data from Vine API
get_vine_user_data() {
    local user_id_str=$1
    local url="https://archive.vine.co/profiles/_/${user_id_str}.json"
    local response=$(curl -s "$url")

    if [[ $(echo "$response" | jq -r '.status') == "200" ]]; then
        local created=$(echo "$response" | jq -r '.created')
        created=$(date -d "$created" '+%B %d, %Y %I:%M:%S %p')
        echo "$response" | jq --arg created "$created" '.created = $created'
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

    if [[ $(echo "$response" | jq -r '.status') == "200" ]]; then
        local user_id_str=$(echo "$response" | jq -r '.data.userIdStr')
        get_vine_user_data "$user_id_str"
    else
        echo "Error: Could not retrieve user information." >&2
        exit 1
    fi
}

# Function to collect post IDs from user profile data
collect_post_ids() {
    local profile_data="$1"
    echo "$profile_data" | jq -r '.posts[]'
}

# Function to download post data
download_post_data() {
    local post_id="$1"
    local user_folder="$2"
    local url="https://archive.vine.co/posts/${post_id}.json"
    local response=$(curl -s "$url")

    if [[ $(echo "$response" | jq -r '.status') == "200" ]]; then
        local post_data="$response"
        local post_folder="${user_folder}/post_${post_id}"
        mkdir -p "$post_folder" || { echo "Error: Could not create folder for post $post_id." >&2; exit 1; }

        local thumbnail_url=$(echo "$post_data" | jq -r '.thumbnailUrl')
        local video_url=$(echo "$post_data" | jq -r '.videoLowURL // .videoURL')

        curl -s "$thumbnail_url" -o "${post_folder}/${post_id}_thumbnail.jpg" || { echo "Error: Could not download thumbnail for post $post_id." >&2; exit 1; }

        if [[ ! -z "$video_url" ]]; then
            curl -s "$video_url" -o "${post_folder}/${post_id}_video.mp4" || { echo "Error: Could not download video for post $post_id." >&2; exit 1; }
        fi

        save_post_data "$post_data" "$post_folder" "${post_id}_post_data.txt"
    else
        echo "Error: Could not retrieve data for post $post_id." >&2
        exit 1
    fi
}

# Function to save post data to a text file
save_post_data() {
    local post_data="$1"
    local folder="$2"
    local filename="$3"
    local description=$(echo "$post_data" | jq -r '.description // "N/A"')
    local likes=$(echo "$post_data" | jq -r '.likes // "N/A"')
    local reposts=$(echo "$post_data" | jq -r '.reposts // "N/A"')
    local loops=$(echo "$post_data" | jq -r '.loops // "N/A"')
    local title=$(echo "$post_data" | jq -r '.entities[0].title // "N/A"')

    cat <<EOF > "${folder}/${filename}"
Description: $description
Likes: $likes
Reposts: $reposts
Loops: $loops
Title: $title
EOF
}

# Function to create user folder and download user info
create_user_folder() {
    local username="$1"
    local profile_data="$2"
    local user_folder="./$username"
    mkdir -p "$user_folder" || { echo "Error: Could not create folder for user $username." >&2; exit 1; }

    local avatar_url=$(echo "$profile_data" | jq -r '.avatarUrl')
    if [[ ! -z "$avatar_url" ]]; then
        curl -s "$avatar_url" -o "${user_folder}/${username}_avatar.jpg" || { echo "Error: Could not download avatar for user $username." >&2; exit 1; }
    fi

    local additional_info=$(get_additional_user_info "$(echo "$profile_data" | jq -r '.userIdStr')")
    cat <<EOF > "${user_folder}/${username}_info.txt"
Status: $(echo "$profile_data" | jq -r '.status // "N/A"')
Vanity URLs: $(echo "$profile_data" | jq -r '.vanityUrls // "N/A"')
Created: $(echo "$profile_data" | jq -r '.created // "N/A"')
User ID: $(echo "$profile_data" | jq -r '.userId // "N/A"')
Posts Count: $(echo "$profile_data" | jq -r '.postCount // "N/A"')
Share URL: $(echo "$profile_data" | jq -r '.shareUrl // "N/A"')
Loop Count: $(echo "$additional_info" | jq -r '.loopCount // "N/A"')
Description: $(echo "$additional_info" | jq -r '.description // "N/A"')
Twitter Screenname: $(echo "$additional_info" | jq -r '.twitterScreenname // "N/A"')
Location: $(echo "$additional_info" | jq -r '.location // "N/A"')
Avatar URL: $(echo "$additional_info" | jq -r '.avatarUrl // "N/A"')
Follower Count: $(echo "$additional_info" | jq -r '.followerCount // "N/A"')
EOF
}

# Function to download a file from URL
download_file() {
    local url="$1"
    local folder="$2"
    local filename="$3"
    curl -s "$url" -o "${folder}/${filename}" || { echo "Error: Could not download file $filename from $url." >&2; exit 1; }
}

# Function to get additional user info from Vine API
get_additional_user_info() {
    local user_id_str="$1"
    local url="https://vine.co/api/users/profiles/${user_id_str}"
    local response=$(curl -s "$url")

    if [[ $(echo "$response" | jq -r '.status') == "200" ]]; then
        echo "$response" | jq -r '.data'
    else
        echo "{}"
    fi
}

# Main script starts here
read -p "Enter a vine vanity or user ID: " vanitydata=$(get_vine_user_info "$vanity")

if [[ "$data" != "Error: Could not retrieve user information." && "$data" != "Error: Could not retrieve user data." ]]; then
    username=$(echo "$data" | jq -r '.username')
    user_folder=$(create_user_folder "$username" "$data")

    post_ids=$(collect_post_ids "$data")

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

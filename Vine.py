import os
import requests
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
from tqdm import tqdm

def get_vine_user_data(user_id_str):
    url = f"https://archive.vine.co/profiles/_/{user_id_str}.json"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        created = datetime.strptime(data["created"], '%Y-%m-%dT%H:%M:%S.%f').strftime('%B %d, %Y %I:%M:%S %p')
        data["created"] = created
        return data
    else:
        return "Error: Could not retrieve user data."

def get_vine_user_info(vanity):
    if vanity.isdigit():
        user_id_str = vanity
        data = get_vine_user_data(user_id_str)
        if data != "Error: Could not retrieve user data.":
            return data
        else:
            return "Error: Could not retrieve user data."
    else:
        url = f"https://vine.co/api/users/profiles/vanity/{vanity}"
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()["data"]
            user_id_str = data["userIdStr"]
            profile_data = get_vine_user_data(user_id_str)
            if profile_data != "Error: Could not retrieve user data.":
                return profile_data
            else:
                return "Error: Could not retrieve user data."
        else:
            return "Error: Could not retrieve user information."

def get_additional_user_info(user_id_str):
    url = f"https://vine.co/api/users/profiles/{user_id_str}"
    response = requests.get(url)
    if response.status_code == 200:
        additional_data = response.json()["data"]
        return additional_data
    else:
        return {}

def collect_post_ids(profile_data):
    posts = profile_data.get("posts", [])
    return posts

def download_post_data(post_id, user_folder):
    url = f"https://archive.vine.co/posts/{post_id}.json"
    response = requests.get(url)

    if response.status_code == 200:
        post_data = response.json()
        post_folder = os.path.join(user_folder, f"post_{post_id}")
        os.makedirs(post_folder, exist_ok=True)
        print(f"Created folder for post {post_id}")

        thumbnail_url = post_data["thumbnailUrl"]
        video_url = post_data.get("videoUrl", post_data.get("videoLowURL"))

        download_file(thumbnail_url, post_folder, f"{post_id}_thumbnail.jpg")
        print(f"Downloaded thumbnail for post {post_id}")

        if video_url:
            download_file(video_url, post_folder, f"{post_id}_video.mp4")
            print(f"Downloaded video for post {post_id} successfully.")
        else:
            print(f"Post {post_id} has no video URL.")

        save_post_data(post_data, post_folder, f"{post_id}_post_data.txt")
        print(f"Created TXT file for post {post_id}")
    else:
        print(f"Error: Could not retrieve data for post {post_id}.")

def download_file(url, folder, filename):
    response = requests.get(url)
    if response.status_code == 200:
        with open(os.path.join(folder, filename), "wb") as file:
            file.write(response.content)

def save_post_data(post_data, folder, filename):
    formatted_data = f"Description: {post_data.get('description', 'N/A')}\n" \
                     f"Likes: {post_data.get('likes', 'N/A')}\n" \
                     f"Reposts: {post_data.get('reposts', 'N/A')}\n" \
                     f"Loops: {post_data.get('loops', 'N/A')}\n" \
                     f"Title: {post_data.get('entities', [{}])[0].get('title', 'N/A')}\n"

    with open(os.path.join(folder, filename), "w", encoding="utf-8") as file:
        file.write(formatted_data)

def create_user_folder(username, profile_data):
    user_folder = os.path.join(os.getcwd(), username)
    os.makedirs(user_folder, exist_ok=True)
    print(f"Created folder for user {username}")

    avatar_url = profile_data.get("avatarUrl", "")
    if avatar_url:
        download_file(avatar_url, user_folder, f"{username}_avatar.jpg")
        print(f"Downloaded avatar for user {username}")

    additional_info = get_additional_user_info(profile_data.get("userIdStr", ""))
    user_info_file = os.path.join(user_folder, f"{username}_info.txt")
    with open(user_info_file, "w", encoding="utf-8") as file:
        file.write(f"Status: {profile_data.get('status', 'N/A')}\n"
                   f"Vanity URLs: {profile_data.get('vanityUrls', 'N/A')}\n"
                   f"Created: {profile_data.get('created', 'N/A')}\n"
                   f"User ID: {profile_data.get('userId', 'N/A')}\n"
                   f"Posts Count: {profile_data.get('postCount', 'N/A')}\n"
                   f"Share URL: {profile_data.get('shareUrl', 'N/A')}\n"
                   f"Loop Count: {additional_info.get('loopCount', 'N/A')}\n"
                   f"Description: {additional_info.get('description', 'N/A')}\n"
                   f"Twitter Screenname: {additional_info.get('twitterScreenname', 'N/A')}\n"
                   f"Location: {additional_info.get('location', 'N/A')}\n"
                   f"Avatar URL: {additional_info.get('avatarUrl', 'N/A')}\n"
                   f"Follower Count: {additional_info.get('followerCount', 'N/A')}\n")
    print(f"Created TXT file for user {username}")

    return user_folder

vanity = input("Enter a vine vanity or user ID: ")
data = get_vine_user_info(vanity)

if data != "Error: Could not retrieve user information." and data != "Error: Could not retrieve user data.":
    username = data.get("username", "")
    user_folder = create_user_folder(username, data)
    print(f"Created folder for user {username}")

    post_ids = collect_post_ids(data)

    if post_ids:
        print(f"Collected {len(post_ids)} post IDs: {post_ids}")

        download_choice = input("Do you want to download data for each post? (yes/no): ").lower()

        if download_choice == "yes":
            with ThreadPoolExecutor(max_workers=5) as executor:
                for post_id in tqdm(post_ids, desc="Downloading posts", unit="post"):
                    executor.submit(download_post_data, post_id, user_folder)
    else:
        print("No posts found for the user.")
else:
    print("Error: Could not retrieve user information.")

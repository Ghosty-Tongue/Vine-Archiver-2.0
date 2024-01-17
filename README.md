# Vine Archiver 2.0

This Python script allows you to retrieve and download both user data and post data from the Vine archive.

## Prerequisites

Make sure you have the following libraries installed:

- `os`
- `requests`
- `datetime`
- `tqdm`

You can install them using:

```pip install requests tqdm datetime os```

## Usage

1. Run the script.
2. Enter a Vine vanity or user ID when prompted.
3. The script will create a folder for the user, download user information, and if available, download data for each post.

## Script Overview

- `get_vine_user_info(vanity)`: Retrieves user information based on Vine vanity or user ID.
- `create_user_folder(username, profile_data)`: Creates a folder for the user and downloads user information.
- `collect_post_ids(profile_data)`: Collects post IDs from user data.
- `download_post_data(post_id, user_folder)`: Downloads data for each post, including thumbnails, videos, and post details.
- `download_file(url, folder, filename)`: Downloads a file from a given URL and saves it to the specified folder.
- `save_post_data(post_data, folder, filename)`: Saves post details to a TXT file.

## Downloaded User Data

The script downloads the following user data:

- Avatar: ![Avatar](./images/avatar.jpg)
- Status: Active
- Vanity URLs: vine.co/user123, user123
- Account Creation Date: January 15, 2023 02:30:00 PM
- User ID: 123456789
- Posts Count: 42
- Share URL: [Share on Vine](https://vine.co/u/123456789)
- Loop Count: 12345
- Description: A Vine enthusiast sharing moments!
- Twitter Screenname: @vineuser123
- Location: New York, NY
- Follower Count: 5678

The downloaded user data is saved in a TXT file within the user's folder.

## Downloaded Post Data

For each post, the script downloads:

- Thumbnail image: ![Thumbnail](./user123/post_123_thumbnail.jpg)
- Video (if available): [Video Link](./user123/post_123_video.mp4)
- Description: Fun times with friends!
- Likes Count: 100
- Reposts Count: 20
- Loops Count: 5000
- Title: Awesome Moment

The downloaded post data is organized in folders within the user's directory.

## Download Choices

After collecting post IDs, the script prompts you to choose whether to download data for each post. If selected, it utilizes ThreadPoolExecutor to download posts concurrently.

Feel free to customize and enhance the script as needed.

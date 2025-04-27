create database socialmedia_optimize; 
use socialmedia_optimize;
select * from social_media;
drop table social_media;

-- calulate the average (likes,share,comment)  and total no of post for individual post types 

SELECT 
    Post_Type,
    AVG(No_of_likes) AS avg_likes,
    AVG(No_of_share) AS avg_shares,
    AVG(No_of_Comments) AS avg_comments,
    COUNT(*) AS post_count
FROM social_media
GROUP BY Post_Type
ORDER BY avg_likes DESC;

-- calculate the average (like,share ,comment) based on platform

SELECT 
    TRIM(Platform) AS Platform,
    AVG(No_of_likes) AS avg_likes,
    AVG(No_of_share) AS avg_shares,
    AVG(No_of_Comments) AS avg_comments
FROM social_media
GROUP BY TRIM(Platform)
ORDER BY avg_likes DESC;

-- calculate the avg (like,commend,share) based on post type in each platform 

SELECT 
    TRIM(Platform) AS Platform,
    Post_Type,
    AVG(No_of_likes + No_of_share + No_of_Comments) AS total_engagement,
    COUNT(*) AS post_count
FROM social_media
GROUP BY TRIM(Platform), Post_Type
ORDER BY Platform, total_engagement DESC;

-- calculate the post count and percentage based on sentiment in each countrys

SELECT 
    TRIM(Country) AS Country,
    Sentiment,
    COUNT(*) AS post_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY TRIM(Country)), 2) AS percentage
FROM social_media
GROUP BY TRIM(Country), Sentiment
ORDER BY Country, post_count DESC;

--  Average likes commend share based sentiment and country

SELECT 
    TRIM(Country) AS Country,
    Sentiment,
    AVG(No_of_likes) AS avg_likes,
    AVG(No_of_share) AS avg_shares,
    AVG(No_of_Comments) AS avg_comments
FROM social_media
GROUP BY TRIM(Country), Sentiment
ORDER BY Country, avg_likes DESC;

-- calulate the  common sentiment and no of post in different platform in each country

WITH ranked_sentiments AS (
    SELECT 
        TRIM(Country) AS Country,
        TRIM(Platform) AS Platform,
        Sentiment,
        COUNT(*) AS post_count,
		rank() OVER (PARTITION BY TRIM(Country), TRIM(Platform) ORDER BY COUNT(*) DESC) AS rank_sent
    FROM social_media
    GROUP BY TRIM(Country), TRIM(Platform), Sentiment
)
SELECT Country, Platform, Sentiment, post_count
FROM ranked_sentiments
WHERE rank_sent = 1
ORDER BY Country, Platform;

-- calulate the average of (like,comment,share) based on post type in different countrys

SELECT 
    Post_Type,trim(country) as country,
    AVG(No_of_likes) AS avg_likes,
	AVG(No_of_share) AS avg_shares,
	AVG(No_of_comments) AS avg_commends,
    COUNT(*) AS post_count
FROM social_media
GROUP BY Post_Type,trim(country)
ORDER BY country, avg_likes DESC;

-- it showes the top 20 user details in all platform

SELECT 
    user_id,
    user_name,
    User_Follower_Count,
    TRIM(Country) AS Country,
    TRIM(Platform) AS Platform
FROM social_media
ORDER BY User_Follower_Count DESC
LIMIT 20;

-- It Show Top 20 user details by engagement rate (engagement per follower)

SELECT 
    user_id,
    user_name,
    TRIM(Platform) AS Platform,
    User_Follower_Count,
    AVG(No_of_likes + No_of_share + No_of_Comments) AS avg_engagement,hours,
    ROUND(AVG(No_of_likes + No_of_share + No_of_Comments) / NULLIF(User_Follower_Count, 0) * 100, 2) AS engagement_rate_percent
FROM social_media
GROUP BY user_id, user_name, Platform, User_Follower_Count,hours
HAVING User_Follower_Count > 1000  -- Filter out accounts with very few followers
ORDER BY engagement_rate_percent DESC
LIMIT 20;

-- Extract year from download_date and analyze performance of each platform based on years

SELECT 
    SUBSTRING(download_date, LENGTH(download_date) - 3, 4) AS year,
    TRIM(Platform) AS Platform,
    AVG(No_of_likes) AS avg_likes,
    AVG(No_of_share) AS avg_shares,
    AVG(No_of_Comments) AS avg_comments,
    COUNT(*) AS post_count
FROM social_media
GROUP BY SUBSTRING(download_date, LENGTH(download_date) - 3, 4), TRIM(Platform)
ORDER BY year, Platform;

-- Extract year from download_date and calculate the post count and percentage based on years and sentiment

SELECT 
    SUBSTRING(download_date, LENGTH(download_date) - 3, 4) AS year,
    Sentiment,
    COUNT(*) AS post_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY SUBSTRING(download_date, LENGTH(download_date) - 3, 4)), 2) AS percentage
FROM social_media
GROUP BY SUBSTRING(download_date, LENGTH(download_date) - 3, 4), Sentiment
ORDER BY year, post_count DESC;

--  it show the Users who post on multiple platforms

SELECT 
    user_name,
    COUNT(DISTINCT TRIM(Platform)) AS platform_count,
    COUNT(*) AS total_posts,
    AVG(No_of_likes) AS avg_likes,
    AVG(No_of_share) AS avg_shares,
    AVG(No_of_Comments) AS avg_comments
FROM social_media
GROUP BY user_name
having COUNT(DISTINCT TRIM(Platform)) > 1
ORDER BY platform_count DESC, total_posts DESC;

-- Compare user performance across 

WITH user_platform_stats AS (
    SELECT 
        user_id,
        user_name,
        TRIM(Platform) AS Platform,
        COUNT(*) AS post_count,
        AVG(No_of_likes) AS avg_likes,
        AVG(No_of_share) AS avg_shares,
        AVG(No_of_Comments) AS avg_comments,
        STDDEV(No_of_likes) AS likes_stddev,
        AVG(No_of_likes) / NULLIF(STDDEV(No_of_likes), 0) AS consistency_score
    FROM social_media
    GROUP BY user_id, user_name, TRIM(Platform)
    HAVING COUNT(*) > 3  
),
cross_platform_users AS (
    SELECT 
        user_id,
        user_name,
        COUNT(DISTINCT Platform) AS platform_count
    FROM user_platform_stats
    GROUP BY user_id, user_name
    HAVING COUNT(DISTINCT Platform) > 1 
)
SELECT 
    c.user_id,
    c.user_name,
    p1.Platform AS platform_1,
    p1.avg_likes AS platform_1_avg_likes,
    p1.avg_shares AS platform_1_avg_shares,
    p1.avg_comments AS platform_1_avg_comments,
    p1.consistency_score AS platform_1_consistency,
    p2.Platform AS platform_2,
    p2.avg_likes AS platform_2_avg_likes,
    p2.avg_shares AS platform_2_avg_shares,
    p2.avg_comments AS platform_2_avg_comments,
    p2.consistency_score AS platform_2_consistency,
    ROUND((p1.avg_likes - p2.avg_likes) / p2.avg_likes * 100, 2) AS like_performance_diff_pct,
    ROUND((p1.avg_shares - p2.avg_shares) / p2.avg_shares * 100, 2) AS share_performance_diff_pct,
    ROUND((p1.avg_comments - p2.avg_comments) / p2.avg_comments * 100, 2) AS comment_performance_diff_pct
FROM cross_platform_users c
JOIN user_platform_stats p1 ON c.user_id = p1.user_id
JOIN user_platform_stats p2 ON c.user_id = p2.user_id AND p1.Platform < p2.Platform
ORDER BY 
    ABS(p1.avg_likes - p2.avg_likes) DESC, 
    c.user_name;
    
   -- create a store procedure  for collet all datas from one country and one platform
   
DELIMITER $$
CREATE PROCEDURE detial(
    IN platform_name VARCHAR(100),
    IN country_name VARCHAR(100))
BEGIN
    SELECT 
        TRIM(Country) AS country,
        TRIM(Platform) AS platform,
        Post_Type,
        COUNT(*) AS post_count,
        ROUND(AVG(No_of_likes), 2) AS avg_likes,
        ROUND(AVG(No_of_share), 2) AS avg_shares,
        ROUND(AVG(No_of_Comments), 2) AS avg_comments
    FROM social_media 
    WHERE TRIM(Platform) = platform_name 
    AND TRIM(Country) = country_name
    GROUP BY TRIM(Country), TRIM(Platform), Post_Type
    ORDER BY Post_Type, post_count DESC;

END$$
DELIMITER ;
drop procedure detial;
call detial("twitter","india");

-- find the top 5 influncer based on country and platform --

DELIMITER $$
CREATE PROCEDURE top_5(
    IN platform_name VARCHAR(100),
    IN country_name VARCHAR(100))
BEGIN
    SELECT 
        user_id,
        user_name,
        TRIM(Platform) AS platform,
        TRIM(Country) AS country,
        User_Follower_Count,
        COUNT(*) AS posts_count,
        ROUND(AVG(No_of_likes), 2) AS avg_likes,
        ROUND(AVG(No_of_share), 2) AS avg_shares,
        ROUND(AVG(No_of_Comments), 2) AS avg_comments
    FROM social_media
    WHERE TRIM(Platform) = platform_name 
    AND TRIM(Country) = country_name
    GROUP BY user_id, user_name, TRIM(Platform), TRIM(Country), User_Follower_Count
    ORDER BY User_Follower_Count DESC
    LIMIT 5;
END$$
DELIMITER ;
drop procedure top_5;
call top_5("facebook","india");

-- user define function--

DELIMITER $$
CREATE FUNCTION user_engagement(user_id_param INT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE result_str VARCHAR(255);
    DECLARE v_username VARCHAR(100);
    DECLARE v_avg_likes DECIMAL(10,2);
	DECLARE v_avg_comment DECIMAL(10,2);
	DECLARE v_avg_share DECIMAL(10,2);
    DECLARE v_platform VARCHAR(50);
	DECLARE v_country VARCHAR(50);
    SELECT 
        TRIM(user_name),
        AVG(No_of_likes),
        avg(No_of_comments),
        avg(No_of_share),
        trim(platform),
		trim(country)
    INTO 
        v_username,
        v_avg_likes,
		v_avg_comment,
	    v_avg_share,
        v_platform,
        v_country
    FROM social_media
    WHERE user_id = user_id_param
    GROUP BY user_id, user_name, Platform,country
    ORDER BY AVG(No_of_likes) DESC
    LIMIT 1;
    IF v_username IS NOT NULL THEN
        SET result_str = CONCAT(
            'User: ', v_username,
            ' | Avg Likes: ', ROUND(v_avg_likes, 2),
            ' | Avg comment: ', ROUND(v_avg_comment, 2), 
            ' | Avg share: ', ROUND(v_avg_share, 2), 
            ' | Platform: ', v_platform,
            ' | country: ', v_country
            );
    ELSE
        SET result_str = CONCAT('User ID ', user_id_param, ' not found');
    END IF;
    RETURN result_str;
END$$
DELIMITER ;
drop function user_engagement;
SELECT user_engagement(345) AS user_engagement;

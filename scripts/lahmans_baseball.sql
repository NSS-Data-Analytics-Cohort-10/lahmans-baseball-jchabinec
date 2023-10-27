-- 1. What range of years for baseball games played does the provided database cover? 
SELECT
	MIN(year) AS oldest_game,
	MAX(year) AS most_recent_game
FROM homegames;
-- ANSWER: 1871-2016 (Also found in data dictionary)

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT
	CONCAT(p.namefirst, ' ', p.namelast) AS name,
	p.height AS height_in_inches,
	a.g_all AS games_played,
	t.name
FROM people AS p
INNER JOIN appearances AS a
	USING(playerid)
INNER JOIN teams AS t
	USING(teamid)
ORDER BY height ASC
LIMIT 1;
--ANSWER: Eddie Gaedel, at  3'-7" tall, played one game for the St. Louis Browns.

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT
	CONCAT(p.namefirst, ' ', p.namelast) AS name,
	SUM(s.salary)::numeric::money AS total_salary
FROM people AS p
INNER JOIN salaries AS s
	USING(playerid)
WHERE playerid IN
	(
	SELECT
		playerid
	FROM collegeplaying
	WHERE schoolid IN
		(
		SELECT schoolid
		FROM schools
		WHERE schoolname ILIKE '%Vanderbilt%'
		)
	)
GROUP BY playerid
ORDER BY total_salary DESC
--ANSWER: David Price has earned the most money in the majors for a Vanderbilt alum, with $81,851,296.

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT
	CASE
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = 'SS'
			OR pos = '1B'
			OR pos = '2B'
			OR pos = '3B'
			THEN 'Infield'
		WHEN pos = 'P'
			OR pos = 'C'
			THEN 'Battery'
		ELSE 'N/A'
	END AS position,
	SUM(po)
FROM fielding
WHERE yearid = 2016
GROUP BY position
--ANSWER:
--	Battery:	41,424 putouts
--	Infield:	58,934 putouts
--	Outfield:	29,560 putouts

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
SELECT
	CASE
		WHEN yearid < 1929 THEN '1920s'
		WHEN yearid < 1939 THEN '1930s'
		WHEN yearid < 1949 THEN '1940s'
		WHEN yearid < 1959 THEN '1950s'
		WHEN yearid < 1969 THEN '1960s'
		WHEN yearid < 1979 THEN '1970s'
		WHEN yearid < 1989 THEN '1980s'
		WHEN yearid < 1989 THEN '1990s'
		WHEN yearid < 1999 THEN '1990s'
		WHEN yearid < 2009 THEN '2000s'
		ELSE '2010s'
	END AS decade,
	SUM(G) AS games_played,
	SUM(so) AS strikeouts,
	SUM(hr) AS home_runs,	
	ROUND(SUM(so)/SUM(G)::numeric,2) AS avg_so_per_game,
	ROUND(SUM(hr)/SUM(G)::numeric,2) AS avg_hr_per_game
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade DESC
-- ANSWER: See query - the average numbers of both strikeouts and home runs per game seems to be increasing with each decade.

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
SELECT
	CONCAT(p.namefirst, ' ', p.namelast) AS name,
	b.sb AS stolen_bases,
	b.cs AS caught_Stealing,
	b.sb+b.cs AS attempts,
	ROUND(b.sb::numeric/(b.sb::numeric+b.cs::numeric),2)*100 AS sb_pct
FROM batting AS b
INNER JOIN people AS p
	USING(playerid)
WHERE
	sb+cs > 20
	AND yearid = 2016
ORDER BY sb_pct DESC
LIMIT 1
-- ANSWER: Chris Owings had teh most success stealing bases in 2016, with a success rate of 91%.

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
SELECT
	yearid,
	name,
	w
FROM teams
WHERE
	yearid > 1970
	AND wswin = 'N'
ORDER BY w DESC
LIMIT 1
--ANSWER: The Seattle Mariners had the most wins for a team that did not win the world series, with 116 wins in 2001.
SELECT
	yearid,
	name,
	w
FROM teams
WHERE
	yearid > 1970
	AND yearid <> 1981
	AND wswin = 'Y'
ORDER BY w ASC
LIMIT 1
-- ANSWER 2: The team with the least wins that went on to win the world series was the Los Angeles Dodgers in 1981, with only 63. However, the 1981 season was shortened due to a players strike, so excluding that year, the St. Louis Cardinals won the world series in 2006 with only 83 wins.

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
WITH attendance_2016 AS
	(
	SELECT 
		team,
		park,
		games,
		AVG(attendance/games::numeric) OVER(PARTITION BY team) AS avg_attendance
	FROM homegames
	WHERE
		year = 2016
		AND games >= 10
	)


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
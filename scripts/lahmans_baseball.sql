-- 1. What range of years for baseball games played does the provided database cover? 
SELECT
	MIN(span_first) AS oldest_game,
	MAX(span_last) AS most_recent_game
FROM homegames;
-- ANSWER: 1871-2016 (Also found in data dictionary)

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT
	CONCAT(p.namefirst, ' ', p.namelast) AS name,
	p.height AS height_in_inches,
	a.g_all AS games_played,
	t.name AS team
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
-- ANSWER: Chris Owings had the most success stealing bases in 2016, with a success rate of 91%.

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
SELECT
	yearid,
	name,
	w
FROM teams
WHERE
	yearid >= 1970
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
	yearid >= 1970
	AND yearid <> 1981
	AND wswin = 'Y'
ORDER BY w ASC
LIMIT 1
-- ANSWER 2: The team with the least wins that went on to win the world series was the Los Angeles Dodgers in 1981, with only 63. However, the 1981 season was shortened due to a players strike, so excluding that year, the St. Louis Cardinals won the world series in 2006 with only 83 wins.
WITH wins AS
	(
	SELECT
		yearid,
		name,
		w,
		CASE
			WHEN w = MAX(w) OVER(PARTITION BY yearid) THEN 'Y'
			ELSE 'N'
		END AS most_wins_in_season,
		wswin
	FROM teams
	)
SELECT
	yearid AS year,
	name AS team,
	w AS wins
FROM wins
WHERE
	yearid >= 1970
	AND yearid <> 1981
	AND most_wins_in_season = 'Y'
	AND wswin = 'Y'
-- ANSWER 3: Between 1970 and 2016, 12 world series winners also had the most wins for the season they won. Excluding the 1981 season, this means that this has happened in roughly 26.67% of these years.

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
--Highest Attendance in 2016
SELECT 
	t.name AS team,
	p.park_name AS park,
	AVG(h.attendance/h.games) OVER(PARTITION BY h.team) AS avg_attendance
FROM homegames AS h
INNER JOIN teams AS t
	ON 	h.team = t.teamid
INNER JOIN parks AS p
	ON p.park = h.park
WHERE
	h.year = 2016
	AND h.games >= 10
	AND t.yearid = 2016
ORDER BY avg_attendance DESC
LIMIT 5
--Lowest Attendance in 2016
SELECT 
	t.name AS team,
	p.park_name AS park,
	AVG(h.attendance/h.games) OVER(PARTITION BY h.team) AS avg_attendance
FROM homegames AS h
INNER JOIN teams AS t
	ON 	h.team = t.teamid
INNER JOIN parks AS p
	ON p.park = h.park
WHERE
	h.year = 2016
	AND h.games >= 10
	AND t.yearid = 2016
ORDER BY avg_attendance
LIMIT 5
-- ANSWERS: See queries

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
SELECT
	CONCAT(p.namefirst, ' ', p.namelast) AS name,
	a.yearid,
	a.lgid AS league,
	t.name AS team
FROM people AS p
INNER JOIN awardsmanagers AS a
	USING(playerid)
INNER JOIN managers AS m
	USING(playerid, yearid)
INNER JOIN teams AS t
	USING(teamid, yearid)
WHERE playerid IN
	(
	SELECT 
		playerid
	FROM awardsmanagers AS a
	WHERE
		a.awardID = 'TSN Manager of the Year'
		AND (a.lgid = 'AL' OR a.lgid = 'NL')
	GROUP BY 
		a.playerid
	HAVING 
		COUNT(DISTINCT a.lgID) = 2
	)
	AND a.awardid = 'TSN Manager of the Year'
-- ANSWER: Jim Leyland won the award with both the Pittsburgh Pirates and the Detroit Tigers, and Davey Johnson won it with the Baltimore Orioles and the Washington Nationals.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
WITH career_hr AS
	(
	SELECT
		playerid,
		yearid,
		COUNT(yearid) OVER (PARTITION BY playerid) AS years_played,
		hr,
		CASE
			WHEN hr = MAX(hr) OVER (PARTITION BY playerid) THEN 'Y'
			ELSE 'N'
		END AS career_high,
		MAX(hr) OVER (PARTITION BY playerid) AS career_high_hr
	FROM batting
	)
SELECT
	CONCAT(p.namefirst, ' ', p.namelast) AS name,
	c.hr
FROM career_hr AS c
INNER JOIN people AS p
	USING(playerid)
WHERE c.years_played >= 10
	AND c.yearid = 2016
	AND c.hr >= 1
	AND c.career_high = 'Y'
ORDER BY c.hr DESC
-- ANSWER: See query - of all players in 2016 that have been in the league for at least 10 years, 13 hit their career highest home runs in 2016.

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
-- First, find each team's wins and total team salary for each season
WITH team_salaries AS
	(SELECT 
		DISTINCT t.yearid AS season,
		t.name AS team,
		t.w AS wins,
		SUM(s.salary::numeric::money) OVER(PARTITION BY yearid, teamid) AS team_salary
	FROM teams AS t
	INNER JOIN salaries AS s
		USING(teamid, yearid)
	WHERE yearid = 2001
	ORDER BY team_salary DESC)
-- Use that as a CTE to find out how much each team spent on salaries per win, per season. Then rank them by each season's wins and compare the "dollars per win" to the average of that metric per season.
SELECT
	season,
	team,
	RANK() OVER(PARTITION BY season ORDER BY wins DESC) AS win_rank,
	team_salary/wins AS dollars_per_win,
	AVG(team_salary::numeric/wins) OVER(PARTITION BY season)::money AS avg_dollars_per_win
FROM team_salaries
-- ANSWER: There doesn't appear to be a correlation between wins and team salaries.
-- To try it another way, let's look at the average number of wins per season over the average dollars per win
WITH team_salaries AS
	(SELECT 
		DISTINCT t.yearid AS season,
		t.name AS team,
		t.w AS wins,
		SUM(s.salary::numeric::money) OVER(PARTITION BY yearid, teamid) AS team_salary
	FROM teams AS t
	INNER JOIN salaries AS s
		USING(teamid, yearid)
	WHERE yearid >= 2000
	ORDER BY team_salary DESC)
SELECT DISTINCT ON(season, team)
	season,
	team,
	wins,
	ROUND(AVG(wins) OVER(PARTITION BY season),0) AS avg_wins,
	RANK() OVER(PARTITION BY season ORDER BY wins DESC) AS win_rank,
	AVG(team_salary::numeric/wins) OVER(PARTITION BY season)::money AS avg_dollars_per_win,
	MAX(team_salary::numeric/wins) OVER(PARTITION BY season)::money AS max_dollars_per_win
FROM team_salaries
-- 12. In this question, you will explore the connection between number of wins and attendance.
-- a. Does there appear to be any correlation between attendance at home games and number of wins?
SELECT DISTINCT ON(t.yearid, t.teamid)
	t.yearid,
	t.name AS team,
	t.w as total_season_wins,
	SUM(h.attendance) OVER(PARTITION BY h.year, h.team) AS home_game_attendance
FROM homegames AS h
INNER JOIN teams AS t
	ON h.team = t.teamid AND h.year = t.yearid

-- b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
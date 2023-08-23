select * 
from mean_temperature
order by date 
limit 10;

alter table stations 
add latitude numeric;

alter table stations 
add longitude numeric;


--Convert the lat, lon coordinates into numerical format

	update stations set latitude = (
		split_part(lat, ':', 1)::numeric + -- the degrees --we add the plus to sum all of them
		split_part(lat, ':', 2)::numeric / 60 + -- the minutes divided by 60
		split_part(lat, ':', 3)::numeric / (60*60) --the seconds divided by 3600 all summed up 
		);

	
	update stations set longitude = (
		split_part(lon, ':',1):: numeric +
		split_part(lon, ':',2):: numeric /60+
		split_part(lon, ':',3):: numeric / (60*60) 
		);
	
SELECT *
FROM yearly_mean_temperature
LIMIT 10;




ALTER TABLE mean_temperature
ADD FOREIGN KEY (staid) REFERENCES stations(staid);

alter table stations 
ADD FOREIGN KEY (cn) REFERENCES countries(alpha2);



--1: How many records are there in the temperature data?
select count (*)
from mean_temperature;


--2: Get a list of all countries included. Remove all duplicates and sort it alphabetically
select distinct name
from countries
order by name
;

--3: Get the number of weather stations for each country. Group by the number of stations in descending order!
select countries.name as country, count(stations.staname) as number_stations
from countries
full join  stations
on countries.alpha2 = stations.cn
group by countries.name
order by number_stations desc;

--4: What’s the average height of stations in Switzerland compared to Netherlands?
select countries.name as country, avg(stations.hght) as average_height
from countries 
join stations
on countries.alpha2 = stations.cn
where name = 'Switzerland' or name = 'Netherlands'
group by countries.name
;

--5: What is the highest station in Germany?
select * 
from stations 
where cn = 'DE'
order by hght 
limit 1;

--6: What’s the minimum and maximum daily average temperature ever recorded in Germany?
select *
from mean_temperature
limit 10;



-- Select countries with station id
select countries.name as country, stations.staid as staid
	from countries
	join stations
	on countries.alpha2 = stations.cn
	where name = 'Germany';



-- Standard deviation temperature over the years in Germany
WITH subquery AS (
    SELECT 
        year,
        SQRT(AVG(diff_squared)) AS standard_deviation
    FROM (
        SELECT 
            extract(year FROM date) AS year,
            POWER(max(tg) - min(tg), 2) AS diff_squared
        FROM 
            mean_temperature
        LEFT JOIN (
            SELECT 
                countries.name AS country, 
                stations.staid AS staid
            FROM 
                countries
            JOIN 
                stations ON countries.alpha2 = stations.cn
            WHERE 
                countries.name = 'Germany'                
        ) AS sub_country ON mean_temperature.staid = sub_country.staid
        WHERE 
            sub_country.staid IS NOT NULL -- Filter records to only include stations in Germany
        GROUP BY 
            extract(year FROM date), mean_temperature.staid
    ) AS subquery
    GROUP BY year
    HAVING SQRT(AVG(diff_squared)) != 0
)
SELECT 
    year,
    standard_deviation,
    AVG(standard_deviation) OVER (ORDER BY year ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING) AS rolling_average
FROM 
    subquery
ORDER BY 
    year;


   
   


--BERLIN    
with subquery as (   
					SELECT 
					    year,
					    month,
					    avg(min_temp) AS avg_min_temp,
					    avg(max_temp) AS avg_max_temp
					FROM (
					    SELECT 
					        extract(year FROM date) AS year,
					        extract (month from date) as month,
					        min(tg) AS min_temp,
					        max(tg) AS max_temp
					    FROM 
					        mean_temperature
					    JOIN (
					        SELECT 
					            stations.staid AS staid
					        FROM 
					            countries
					        JOIN 
					            stations ON countries.alpha2 = stations.cn
					        WHERE 
					            countries.name = 'Germany' and staid = 41         
					    ) AS subquery
					    ON mean_temperature.staid = subquery.staid
					    GROUP BY year, month
					) AS temperature_data
					where month = 1
					GROUP BY year, month)
SELECT 
    year,
    avg_min_temp as avg_min_temp,
    avg_max_temp as avg_max_temp,
    AVG(avg_min_temp) OVER (ORDER BY year ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING) AS rolling_av_min,
    AVG(avg_max_temp) OVER (ORDER BY year ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING) AS rolling_av_max
FROM 
    subquery
ORDER BY 
    year; 

   
   

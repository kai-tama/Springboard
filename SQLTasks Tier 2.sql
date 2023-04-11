
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT * FROM Facilities WHERE membercost > 0.0;

/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT(membercost) AS free_mem_facs FROM Facilities WHERE membercost = 0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance FROM `Facilities` 
WHERE membercost > 0 AND membercost < (monthlymaintenance * .2);

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT * FROM `Facilities` WHERE name LIKE '%2';

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance, expense_label FROM `Facilities`;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT surname, firstname FROM 'Members' WHERE memid = 37;

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT CONCAT(m.surname, ', ',  m.firstname) AS full_name, f.name AS facility
FROM Bookings AS b 
LEFT JOIN Members AS m 
ON b.memid = m.memid 
LEFT JOIN Facilities AS f 
ON b.facid = f.facid
WHERE f.facid BETWEEN 0 AND 1
ORDER BY full_name;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT CONCAT(m.surname, ', ', m.firstname) AS full_name, f.name AS facility, 
    SUM(CASE WHEN b.memid > 0 THEN b.slots*f.membercost ELSE 0 END + 
 	CASE WHEN b.memid = 0 THEN b.slots*f.guestcost ELSE 0 END) AS booking_total
FROM Bookings AS b
LEFT JOIN Members AS m 
ON b.memid = m.memid 
LEFT JOIN Facilities AS f 
ON b.facid = f.facid
WHERE starttime LIKE '2012-09-14%'
GROUP BY full_name, f.name
HAVING booking_total >= 30.0
ORDER BY booking_total DESC;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

WITH tbl AS
	(
        SELECT CONCAT(Members.surname, ', ', Members.firstname) AS full_name, Facilities.name AS facility_name, SUM(CASE WHEN Bookings.memid > 0 THEN Bookings.slots*Facilities.membercost ELSE 0 END + 
        CASE WHEN Bookings.memid = 0 THEN Bookings.slots*Facilities.guestcost ELSE 0 END) AS booking_total
    	FROM Bookings
    	JOIN Members ON Bookings.memid = Members.memid
        JOIN Facilities ON Bookings.facid = Facilities.facid
        WHERE Bookings.starttime LIKE '2012-09-14%'
        GROUP BY full_name, facility_name
    )
SELECT *
FROM tbl
WHERE booking_total >= 30
ORDER BY booking_total DESC;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

WITH tbl AS ( SELECT Facilities.name AS facility_name, \
    ROUND(SUM(CASE WHEN Bookings.memid > 0 THEN Bookings.slots*Facilities.membercost ELSE 0 END + CASE WHEN \
    Bookings.memid = 0 THEN Bookings.slots*Facilities.guestcost ELSE 0 END), 2) - (Facilities.monthlymaintenance * 12) \
    AS revenue FROM Bookings JOIN Members ON Bookings.memid = Members.memid JOIN Facilities ON Bookings.facid = \
    Facilities.facid GROUP BY facility_name, Facilities.monthlymaintenance ) SELECT facility_name, revenue FROM tbl \
    WHERE revenue < 1000 GROUP BY facility_name, revenue ORDER BY revenue DESC;

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT m1.surname || ', ' || m1.firstname AS member_name, m2.surname || ', ' || m2.firstname AS recommended_by \
    FROM Members AS m1 JOIN Members AS m2 ON m1.recommendedby = m2.memid WHERE m1.recommendedby != 0 ORDER BY member_name;

/* Q12: Find the facilities with their usage by member, but not guests */

SELECT Members.memid AS mem_id, Members.surname || ', ' || Members.firstname AS member_name, \
    Facilities.name AS facility_name, SUM(Bookings.slots) AS mem_fac_usage FROM Bookings JOIN Facilities ON \
    Bookings.facid = Facilities.facid JOIN Members ON Bookings.memid = Members.memid WHERE Bookings.memid > 0 \
    GROUP BY mem_id, member_name, facility_name ORDER BY member_name;

/* Q13: Find the facilities usage by month, but not guests */

SELECT STRFTIME('%m', Bookings.starttime) AS month, Facilities.name AS facility_name, \
    SUM(Bookings.slots) AS mem_fac_usage FROM Bookings JOIN Facilities ON Bookings.facid = Facilities.facid \
    WHERE Bookings.memid > 0 GROUP BY month, facility_name ORDER BY month;
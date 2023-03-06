/* BAN130 Final Project - Group 6
	Arunadevi Krishnan
	Dhananjay Kumar
	Manish Kumar
	Pratik Harshad Gherwada	*/
	
/* importing the flight delay file */

FILENAME REFFILE '/home/u60685886/BAN130 Workshops and Quiz/FlightDelaysMain.xlsx';

PROC IMPORT DATAFILE=REFFILE DBMS=XLSX OUT=flight;
RUN;

title 'First 100 observation of FlightsDelays dataset';
proc print data=flight(obs=100);
run;

title 'Identifying the missing values using mean proc';
proc means data=flight nmiss n;
run;

*Fixing the time variable dep_time crs_dep_time;
data flight_new;
set flight;
departure_time = input(put(dep_time,z4.),hhmmss4.) ;
format departure_time time5. ;
crs_departure_time = input(put(crs_dep_time,z4.),hhmmss4.) ;
format crs_departure_time time5.;
drop dep_time crs_dep_time;
rename departure_time=dep_time;
rename crs_departure_time=crs_dep_time;
run;


*Section A;

*Step 1;
proc format;
	value missingcount
 .='missing' other='notmissing';
	value $Missingchar ' '='Missing' other='NonMissing';
run;

proc freq data=flight_new;
	table CRS_DEP_TIME DEP_TIME DISTANCE FL_DATE FL_NUM carrier dest flight_status 
		origin tail_num Weather DAY_WEEK DAY_OF_MONTH /missing;
	format CRS_DEP_TIME missingcount.  DEP_TIME missingcount.  DISTANCE 
		missingcount. FL_DATE missingcount. FL_NUM missingcount. Weather 
		missingcount. DAY_WEEK missingcount. DAY_OF_MONTH 
		missingcount. carrier $missingchar. dest $missingchar. 
		flight_status $missingchar. origin $missingchar. tail_num $missingchar.;
run;

data flight_new2;
	set flight_new;
	if missing(crs_dep_time) or missing(dep_time) or missing(distance) or 
		missing(fl_date) or missing(fl_num) or missing(carrier) or missing(dest) or 
		missing(dest) or missing(flight_status) or missing(origin) or 
		missing(tail_num) then
			delete;
run;

title 'Checking missing values after handling';
proc means data=flight_new2 nmiss n;
run;

*Step 2;

data flightdelays replace;
set flight_new2;
	where Origin="DCA";
	if Flight_status="delayed" then
		DelayedFlight=1;
	else if Flight_status="ontime" then
		DelayedFlight=0;
	if Flight_status="delayed" then
	delay_time_minutes=(dep_time-crs_dep_time)/60;
	else delay_time_minutes=0;
run;

*Step 3;
data flight_delay replace;
set flightdelays;
where fl_date<01/09/2004;
where flight_status="delayed";
run;

proc sql;
create table delayed_avg as
select avg(delay_time_minutes) as delayed_avg_minutes, dest from flight_delay group by dest;
run;

proc sgplot data=delayed_avg;
  yaxis label="delayed_avg_minutes" max=60;
  vbar dest / response=delayed_avg_minutes;  
  run;
  
*Step 4;
proc sql;
create table flight_count as
select count(distinct fl_num) as flight_count, carrier, fl_date 
 from flightdelays  group by carrier,fl_date;

create table mean_flights as 
select round(avg(flight_count)) as mean_flights, carrier from flight_count group by carrier;
run;

title "Flights per day for Carrier RU";
proc sgplot data=flight_count ;
where carrier="RU";
   scatter y=flight_count x=fl_date ;
run;

title "Average flights per day by Carrier";
proc sgplot data=mean_flights ;
  yaxis label="mean_flights" max=25;
  vbar carrier  / response=mean_flights;  
  run;

*Step 5;
proc univariate data=flightdelays;
var distance delay_time_minutes;
histogram ;
run;

*Step 6;
ods noproctitle;
ods graphics / imagemap=on;

title "Flight status by Origin";
proc means data=flight_new2 nonobs chartype n vardef=df;
	var FL_NUM;
	class ORIGIN Flight_status;
run;

title "Flight Status for different carrier";
proc means data=flight_new2 nonobs chartype  n vardef=df;
	var FL_NUM;
	class Flight_status CARRIER;
run;

title "Destination and distance affecting flight status ";
proc means data=flight_new2 nonobs chartype n vardef=df;
	var FL_NUM;
	class Flight_status DEST DISTANCE;
run;

title "Weather affecting flight status";
proc means data=flight_new2 nonobs chartype n vardef=df;
	var FL_NUM;
	class Flight_status Weather ORIGIN;
run;

*Section B;

*step-1;
data FlightDelaysTrainingData replace;
set flightdelays (drop= DAY_WEEK DAY_OF_MONTH TAIL_NUM flight_status );
run;

proc export data=FlightDelaysTrainingData
outfile="/home/u60685886/BAN130 Workshops and Quiz/SAS output/FlightDelaysTrainingData" dbms=csv;
run;

title 'Contents on the data reduction data set - FlightDelaysTrainingData';
proc contents data= FlightDelaysTrainingData varnum;
run;

*Step 2;

data FlightDelaysTrainingData;
set FlightDelaysTrainingData;
if carrier="CO" then carrier_num=1;
else if carrier='DH' then carrier_num=2;
else if carrier='DL' then carrier_num=3;
else if carrier='MQ' then carrier_num=4;
else if carrier='OH' then carrier_num=5;
else if carrier='RU' then carrier_num=6;
else if carrier='US' then carrier_num=7;
else if carrier='UA' then carrier_num=9;
if origin="BWI" then origin_num=1;
else if origin="DCA" then origin_num=2;
else if origin="IAD" then origin_num=3;
if dest="EWR" then dest_num=1;
else if dest="JFK" then dest_num=2;
else if dest="LGA" then dest_num=3;
drop carrier origin dest;
rename origin_num=origin;
rename carrier_num=carrier;
rename dest_num=dest;
run;

title 'Data after conversion';
proc print data=FlightDelaysTrainingData (obs=5);
run;

*Creating a reference tables for data conversion;
proc sql;
create table referencetable
 (carrier_no num,carrier char(20),
 origin_no num, origin char(20),
 dest_no num, dest char(20));
quit;

Proc sql;
Insert into referencetable values(1, 'CO',1,'BWI',1,'EWR');
Insert into referencetable values(2, 'DH',2,'DCA',2,'JFK');
Insert into referencetable values(3, 'DL',3,'IAD',3,'LGA');
Insert into referencetable (carrier_no,carrier)values (4, 'MQ');
Insert into referencetable (carrier_no,carrier) values(5, 'OH');
Insert into referencetable (carrier_no,carrier) values(6, 'RU');
Insert into referencetable (carrier_no,carrier) values(7, 'US');
Insert into referencetable (carrier_no,carrier) values(8, 'UA');

title 'Data after conversion reference table';
proc sql;
select origin_no,origin from referencetable 
where origin_no=2;

*Step-3;
title "Fitting a Prediction Model for Flight Delay";
*Removed dest, origin and distance field as they did not add value to the model, 
removing those variables increased the R-squared value by approx 15%;
proc pls data=FlightDelaysTrainingData plots=all;
            model delayedflight=weather|carrier;
run;
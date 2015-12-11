#!/bin/bash 
#this shell refers to a config file, airfarecheckerconfig.txt
#this shell creates several temporary files;
#temp1.txt contains the full html text result of the search
#temp2.txt contains the list of fares
#temp3.txt contains the parsed and labelled html 
#temp4.txt contains the line numbers of the cheapest fares
#temp5.txt contains the line numbers and departure dates.
#temp6.txt contains labelled flights with line numbers.
#variables used by this program are; $day, $month, $year, $mode, $flights, $origin, $destination, $cheapest, $email, ###
#$address, $r1-5, $d1-15, $q1-5, $f1-5, $numcheapest. 

#clear all variables and temp files to avoid errors

#check to see if computer is online


#read mode from config file
mode=`grep mode airfarecheckerconfig.txt | cut -d ":" -f 2`
#test if in getaway or auto mode
if [ $mode = 'auto' ]; then
	#get dates from config file
	day=`grep day airfarecheckerconfig.txt | cut -d ":" -f 2`
	month=`grep month airfarecheckerconfig.txt | cut -d ":" -f 2`
	year=`grep year airfarecheckerconfig.txt | cut -d ":" -f 2`
	#get origin and destination from config file  
	destination=`grep destination airfarecheckerconfig.txt | cut -d ":" -f 2`
	origin=`grep origin airfarecheckerconfig.txt | cut -d ":" -f 2`
	
elif [ $mode = 'getaway' ]; then
	#get current date, set as variables
	day=$(date +%d)
	month=$(date +%m)
	year=$(date +%Y)
	#get origin and destination from config file  
	destination=`grep destination airfarecheckerconfig.txt | cut -d ":" -f 2`
	origin=`grep origin airfarecheckerconfig.txt | cut -d ":" -f 2`

else 
	#ask everything
	echo 'Type the three digit airport code would you like to fly FROM then hit enter'
	read -n 3 origin
		#make sure origin is one of the served cities
		while [ `grep -c "$origin" cities.txt` != "1" ]; do
			echo ""
			echo "Please enter a valid 3 digit capitalized airport code"
			echo "you entered $origin" 
			read -n 3 origin
			done

	echo 'Type the three digit airport code would you like to fly TO then hit enter'
	read -n 3 destination
		#make sure destination is one of the served cities
		while [ `grep -c "$destination" cities.txt` != "1" ]; do
			echo ""
			echo "Please enter a valid 3 digit capitalized airport code"
			echo "you entered $destination" 
			read -n 3 destination
			done
	echo 'Would you like to check flights for the next two weeks? hit y or n then enter'
	read -n 1 getaway
		while [ $getaway != "y" -a $getaway != "n" ]
		do
			echo ""
			echo "Please type y or n, you typed $getaway"
			read -n 1 getaway
		done
		if [ $getaway =  "y" ]; then
			mode=getaway
			#get current date, set as variables
			day=$(date +%d)
			month=$(date +%m)
			year=$(date +%Y)
		elif [ $getaway = n ]; then
			#ask user for desired dates, flights
			echo 'This program will find all flights 15 days from your selected date.' 					
			echo 'Please enter the two digit number of the month you wish to search'
			read -n 2 month
			echo ""
			echo 'Please enter the two digit date you wish to search'
			echo ""
			read -n 2 day
			echo ""
			echo 'Please enter the four digit year you wish to search'
			read -n 4 year
		fi 
fi
#now determine what currency we are working with
currency=`grep "$origin" cities.txt | cut -d ":" -f 2`			
#######here is a possible fork, will choose which airline to search#########
echo "Searching Air Asia for your destinations"
#get html file of search results using variables from config file (or current date)
wget "http://www.airasiaplus.com/search.php?fMonth=$month&fDay=$day&fYear=$year&fOrigin=$origin&fDestination=$destination&B1=Search+AirAsia+Flights" -O - -q > temp1.txt
#clean up html text for parsing by grep
sed -i 's/ *//g' temp1.txt
#parse into dates, times, and fare prices
grep -o '.[0-9]\.[A-Z][a-z]*201[0-9]\|[0-9][0-9][0-9][0-9].[A-Z][A-Z][A-Z].\|[0-9]*,*[0-9]*[0-9][0-9]\.00' temp1.txt > temp3.txt
#count flights found
flights=`grep -c "[0-9][0-9][0-9][0-9].$origin." temp3.txt`
#tell user how many flights we found
if [ $flights = '0' ]; then
	echo ""
	echo "Sorry, couldn't find any flights."
	exit
else
	echo ""
	echo "Found $flights flights from $origin to $destination, across two weeks starting $day/$month."
fi
#make the output look nice 
sed -i "/$origin/s|^| Departs at |g" temp3.txt
sed -i "/$destination/s|^| Arrives at |g" temp3.txt
sed -i "/[0-9]\.00/s|^| Fare: |g" temp3.txt
#separate out the actual fare price
grep 'Fare' temp3.txt | cut -d ":" -f 2 > temp2.txt
#remove leading spaces
sed -i s/^\s*//g temp2.txt
sed -i s/,//g temp2.txt
#sort the prices, find the cheapest
cheapest=`sort -g temp2.txt | grep -m 1 "[0-9]*"`

#number the reference file
grep -n "^>\|^." temp3.txt > temp6.txt
#tell the user what the cheapest fare was
echo ""
echo "The cheapest fare for the 15 days following $day/$month was $cheapest $currency"				
				##begin sorting cheapest fares with cheapest dates##
#get the line numbers of he cheapest fares- put them in temp4.txt
grep -n "$cheapest" temp3.txt | cut -d ":" -f 1 > temp4.txt
#count the cheapest fares
numcheapest=`grep -c "[0-9]*" temp4.txt`
#get the line numbers of the dates- put them in temp5.txt
grep -n -m 15 "^>\|^[0-9]" temp3.txt > temp5.txt
#set each date line number as a date variable
d1=`sed -n '1 p' < temp5.txt | cut -d ":" -f 1`
d2=`sed -n '2 p' < temp5.txt | cut -d ":" -f 1` 
d3=`sed -n '3 p' < temp5.txt | cut -d ":" -f 1`
d4=`sed -n '4 p' < temp5.txt | cut -d ":" -f 1`
d5=`sed -n '5 p' < temp5.txt | cut -d ":" -f 1`
d6=`sed -n '6 p' < temp5.txt | cut -d ":" -f 1`
d7=`sed -n '7 p' < temp5.txt | cut -d ":" -f 1`
d8=`sed -n '8 p' < temp5.txt | cut -d ":" -f 1`
d9=`sed -n '9 p' < temp5.txt | cut -d ":" -f 1`
d10=`sed -n '10 p' < temp5.txt | cut -d ":" -f 1`
d11=`sed -n '11 p' < temp5.txt | cut -d ":" -f 1`
d12=`sed -n '12 p' < temp5.txt | cut -d ":" -f 1`
d13=`sed -n '13 p' < temp5.txt | cut -d ":" -f 1`
d14=`sed -n '14 p' < temp5.txt | cut -d ":" -f 1`
d15=`sed -n '15 p' < temp5.txt | cut -d ":" -f 1`
####associate the cheapest fares with the dates of them, turn them all into variables##
echo "$numcheapest flights were found at that fare"
f1=`sed -n '1 p' < temp4.txt` ##no if statement means that it will always display one cheapest fare
q1=`grep -B2 -m 1 "^$f1" temp6.txt | cut -d ":" -f 2,3`
if [ "$f1" -lt "$d2" ];  then
	
	r1=`sed -n '1 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d3" -a "$f1" -gt "$d2" ];  then
	r1=`sed -n '2 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d4" -a "$f1" -gt "$d3" ];  then
	r1=`sed -n '3 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d5" -a "$f1" -gt "$d4" ];  then
	r1=`sed -n '4 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d6" -a "$f1" -gt "$d5" ];  then
	r1=`sed -n '5 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d7" -a "$f1" -gt "$d6" ];  then
	r1=`sed -n '6 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d8" -a "$f1" -gt "$d7" ];  then
	r1=`sed -n '7 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d9" -a "$f1" -gt "$d8" ];  then
	r1=`sed -n '8 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d10" -a "$f1" -gt "$d9" ];  then
	r1=`sed -n '9 p' < temp5.txt | cut -d ":" -f 2`	
elif [ "$f1" -lt "$d11" -a "$f1" -gt "$d10" ];  then
	r1=`sed -n '10 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d12" -a "$f1" -gt "$d11" ];  then
	r1=`sed -n '11 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d13" -a "$f1" -gt "$d12" ];  then
	r1=`sed -n '12 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d14" -a "$f1" -gt "$d13" ];  then
	r1=`sed -n '13 p' < temp5.txt | cut -d ":" -f 2`
elif [ "$f1" -lt "$d15" -a "$f1" -gt "$d14" ];  then
	r1=`sed -n '14 p' < temp5.txt | cut -d ":" -f 2`
else 
	r1=`sed -n '15 p' < temp5.txt | cut -d ":" -f 2`
fi
#set result 2 r2

if [ $numcheapest -gt "1" ]; then	#if statement means after 1st cheapest, display is conditional
	f2=`sed -n '2 p' < temp4.txt`
	#cut out flight details of #2 best fare
	q2=`grep -B2 -m 1 "^$f2" temp6.txt | cut -d ":" -f 2,3`
	#get date of #2 best fare
	if [ "$f2" -lt "$d2" ];  then
	
		r2=`sed -n '1 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d3" -a "$f2" -gt "$d2" ];  then
		r2=`sed -n '2 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d4" -a "$f2" -gt "$d3" ];  then
		r2=`sed -n '3 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d5" -a "$f2" -gt "$d4" ];  then
		r2=`sed -n '4 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d6" -a "$f2" -gt "$d5" ];  then
		r2=`sed -n '5 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d7" -a "$f2" -gt "$d6" ];  then
		r2=`sed -n '6 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d8" -a "$f2" -gt "$d7" ];  then
		r2=`sed -n '7 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d9" -a "$f2" -gt "$d8" ];  then
		r2=`sed -n '8 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d10" -a "$f2" -gt "$d9" ];  then
		r2=`sed -n '9 p' < temp5.txt | cut -d ":" -f 2`	
	elif [ "$f2" -lt "$d11" -a "$f2" -gt "$d10" ];  then
		r2=`sed -n '10 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d12" -a "$f2" -gt "$d11" ];  then
		r2=`sed -n '11 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d13" -a "$f2" -gt "$d12" ];  then
		r2=`sed -n '12 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d14" -a "$f2" -gt "$d13" ];  then
		r2=`sed -n '13 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f2" -lt "$d15" -a "$f2" -gt "$d14" ];  then
		r2=`sed -n '14 p' < temp5.txt | cut -d ":" -f 2`
	else 
		r2=`sed -n '15 p' < temp5.txt | cut -d ":" -f 2`
	fi
fi	
if [ $numcheapest -gt "2" ]; then
	f3=`sed -n '3 p' < temp4.txt`
	q3=`grep -B2 -m 1 "^$f3" temp6.txt | cut -d ":" -f 2,3`
	if [ "$f3" -lt "$d2" ];  then
	
		r3=`sed -n '1 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d3" -a "$f3" -gt "$d2" ];  then
		r3=`sed -n '2 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d4" -a "$f3" -gt "$d3" ];  then
		r3=`sed -n '3 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d5" -a "$f3" -gt "$d4" ];  then
		r3=`sed -n '4 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d6" -a "$f3" -gt "$d5" ];  then
		r3=`sed -n '5 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d7" -a "$f3" -gt "$d6" ];  then
		r3=`sed -n '6 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d8" -a "$f3" -gt "$d7" ];  then
		r3=`sed -n '7 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d9" -a "$f3" -gt "$d8" ];  then
		r3=`sed -n '8 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d10" -a "$f3" -gt "$d9" ];  then
		r3=`sed -n '9 p' < temp5.txt | cut -d ":" -f 2`	
	elif [ "$f3" -lt "$d11" -a "$f3" -gt "$d10" ];  then
		r3=`sed -n '10 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d12" -a "$f3" -gt "$d11" ];  then
		r3=`sed -n '11 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d13" -a "$f3" -gt "$d12" ];  then
		r3=`sed -n '12 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d14" -a "$f3" -gt "$d13" ];  then
		r3=`sed -n '13 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f3" -lt "$d15" -a "$f3" -gt "$d14" ];  then
		r3=`sed -n '14 p' < temp5.txt | cut -d ":" -f 2`
	else 
		r3=`sed -n '15 p' < temp5.txt | cut -d ":" -f 2`
	fi
fi	
if [ $numcheapest -gt "3" ]; then
	
	f4=`sed -n '4 p' < temp4.txt`
	q4=`grep -B2 -m 1 "^$f4" temp6.txt | cut -d ":" -f 2,3`
	if [ "$f4" -lt "$d2" ];  then
	
		r4=`sed -n '1 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d3" -a "$f4" -gt "$d2" ];  then
		r4=`sed -n '2 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d4" -a "$f4" -gt "$d3" ];  then
		r4=`sed -n '3 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d5" -a "$f4" -gt "$d4" ];  then
		r4=`sed -n '4 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d6" -a "$f4" -gt "$d5" ];  then
		r4=`sed -n '5 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d7" -a "$f4" -gt "$d6" ];  then
		r4=`sed -n '6 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d8" -a "$f4" -gt "$d7" ];  then
		r4=`sed -n '7 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d9" -a "$f4" -gt "$d8" ];  then
		r4=`sed -n '8 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d10" -a "$f4" -gt "$d9" ];  then
		r4=`sed -n '9 p' < temp5.txt | cut -d ":" -f 2`	
	elif [ "$f4" -lt "$d11" -a "$f4" -gt "$d10" ];  then
		r4=`sed -n '10 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d12" -a "$f4" -gt "$d11" ];  then
		r4=`sed -n '11 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d13" -a "$f4" -gt "$d12" ];  then
		r4=`sed -n '12 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d14" -a "$f4" -gt "$d13" ];  then
		r4=`sed -n '13 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f4" -lt "$d15" -a "$f4" -gt "$d14" ];  then
		r4=`sed -n '14 p' < temp5.txt | cut -d ":" -f 2`
	else 
		r4=`sed -n '15 p' < temp5.txt | cut -d ":" -f 2`
	fi
fi	
if [ $numcheapest -gt "4" ]; then
	

	f5=`sed -n '5 p' < temp4.txt`
	q5=`grep -B2 -m 1 "^$f5" temp6.txt | cut -d ":" -f 2,3`
	if [ "$f5" -lt "$d2" ];  then

		r5=`sed -n '1 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d3" -a "$f5" -gt "$d2" ];  then
		r5=`sed -n '2 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d4" -a "$f5" -gt "$d3" ];  then
		r5=`sed -n '3 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d5" -a "$f5" -gt "$d4" ];  then
		r5=`sed -n '4 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d6" -a "$f5" -gt "$d5" ];  then
		r5=`sed -n '5 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d7" -a "$f5" -gt "$d6" ];  then
		r5=`sed -n '6 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d8" -a "$f5" -gt "$d7" ];  then
		r5=`sed -n '7 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d9" -a "$f5" -gt "$d8" ];  then
		r5=`sed -n '8 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d10" -a "$f5" -gt "$d9" ];  then
		r5=`sed -n '9 p' < temp5.txt | cut -d ":" -f 2`	
	elif [ "$f5" -lt "$d11" -a "$f5" -gt "$d10" ];  then
		r5=`sed -n '10 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d12" -a "$f5" -gt "$d11" ];  then
		r5=`sed -n '11 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d13" -a "$f5" -gt "$d12" ];  then
		r5=`sed -n '12 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d14" -a "$f5" -gt "$d13" ];  then
		r5=`sed -n '13 p' < temp5.txt | cut -d ":" -f 2`
	elif [ "$f5" -lt "$d15" -a "$f5" -gt "$d14" ];  then
		r5=`sed -n '14 p' < temp5.txt | cut -d ":" -f 2`
	else 
		r5=`sed -n '15 p' < temp5.txt | cut -d ":" -f 2`
	fi	
fi
###this part displays the results on the terminal###
if [ $numcheapest = "1" ]; then
	#display results
	echo "The best fare was found on:"
	echo "$r1$q1"
	unset day unset month unset year unset mode unset flights unset origin 
	unset destination unset cheapest unset email
	unset address unset r1  unset d1 unset d2
 	unset d3 unset d4 unset d5 unset d6 unset d7 unset d8 unset d9 unset d10 
	unset d11 unset d12 unset d13 unset d14 unset d15 unset q1  	
	unset f1    unset numcheapest
	exit
elif [ $numcheapest = "2" ]; then
	echo "The best fares were found on:"
	echo "$r1$q1,"
	echo "$r2$q2"
	unset day unset month unset year unset mode unset flights unset origin 
	unset destination unset cheapest unset email
	unset address unset r1 unset r2   unset d1 unset d2
 	unset d3 unset d4 unset d5 unset d6 unset d7 unset d8 unset d9 unset d10 
	unset d11 unset d12 unset d13 unset d14 unset d15 unset q1 unset q2  	
	unset f1 unset f2   unset numcheapest
	exit
elif [ $numcheapest = "3" ]; then
	echo "The best fares were found on:"
	echo "$r1$q1,"
	echo "$r2$q2,"
	echo "$r3$q3"
	unset day unset month unset year unset mode unset flights unset origin 
	unset destination unset cheapest unset email
	unset address unset r1 unset r2 unset r3   unset d1 unset d2
 	unset d3 unset d4 unset d5 unset d6 unset d7 unset d8 unset d9 		unset d10 
	unset d11 unset d12 unset d13 unset d14 unset d15 unset q1 unset q2 		
	unset q3 	
	unset f1 unset f2 unset f3  unset numcheapest
	exit
elif [ $numcheapest = "4" ]; then
	echo "The best fares were found on:"
	echo "$r1$q1,"
	echo "$r2$q2,"
	echo "$r3$q3,"
	echo "$r4$q4"
	#clear all variables and temp files to avoid errors in subsequent runs
	unset day unset month unset year unset mode unset flights unset origin 
	unset destination unset cheapest unset email
	unset address unset r1 unset r2 unset r3 unset r4  unset d1 unset d2
 	unset d3 unset d4 unset d5 unset d6 unset d7 unset d8 unset d9 unset d10 
	unset d11 unset d12 unset d13 unset d14 unset d15 unset q1 unset q2 unset q3 	
	unset q4 unset f1 unset f2 unset f3 unset f4 unset numcheapest
	exit
elif [ $numcheapest -gt "4" ]; then
	echo "The best fares were found on:"
	echo "$r1$q1,"
	echo "$r2$q2,"
	echo "$r3$q3,"
	echo "$r4$q4,"
	echo "$r5$q5"
	#clear all variables and temp files to avoid errors in subsequent runs
	unset day unset month unset year unset mode unset flights unset origin 
	unset destination unset cheapest unset email
	unset address unset r1 unset r2 unset r3 unset r4 unset r5 unset d1 unset d2 
	unset d3 unset d4 unset d5 unset d6 unset d7 unset d8 unset d9 unset d10 
	unset d11 unset d12 unset d13 unset d14 unset d15 unset q1 unset q2 unset q3 
	unset q4 unset q5 unset f1 unset f2 unset f3 unset f4 unset f5 unset numcheapest
	exit
else 
	echo "No fares found"
	#clear all variables and temp files to avoid errors in subsequent runs
	unset day unset month unset year unset mode unset flights unset origin 
	unset destination unset cheapest unset email
	unset address unset d1 unset d2 unset d3 unset d4 unset d5 unset d6 unset d7 	
	unset d8 unset d9 unset d10 unset d11 unset d12 unset d13 
	unset d14 unset d15  unset numcheapest
	exit
fi


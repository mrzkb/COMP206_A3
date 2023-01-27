#!/bin/bash 
# Mira Kandlikar-Bloch, U1 Computer Science, mira.kandlikar-bloch@mail.mcgill.ca (student id: 261035244) 

if [[ $# != 1 ]]
then 
	echo Usage: ./logparser.bash "<logdir>"
	exit 1

elif [[ ! -d $1 ]]
then 
	echo Error $1 is not a valid directroy >&2 #direct to stderr 
	exit 2

fi 
logFiles=$(find $1 -name '*.log') 
count=0
for file in $logFiles
do
	count=$(expr $count + 1) #counts how many files in $logFiles 
	broadcastProcess=$(basename -s .log "$file" | sed 's/\./\:/' ) #process name 
	OLDIFS="$IFS"
	IFS=$'\n' #change field seporator to newline so we can loop through lines 
	for line in $(grep -w 'broadcastMsg' $file)  #loop through all the broadcast messages in the file 
	do
		IFS=$OLDIFS
		messageId=$(echo $line | awk '{print $NF}') 
		broadcastTime=$(echo $line | awk '{print $4}')
	
		for i in $logFiles #loop through the files to match the messageId and broadcast 
		do 	
			receivedMessage="Received a message from. message: [senderProcess:$broadcastProcess:val:$messageId]"
			receivedMsg=$(grep -F "$receivedMessage" $i) #look for the recieved message in the file 
		
			receivingProcess=$(basename -s .log "$i" | sed 's/\./\:/' ) #the name of the receiving process 
			receivedTime=$(echo $receivedMsg | awk '{print $4}')

			deliveryMessage="deliver INFO: Received :$messageId from : $broadcastProcess" 
			deliveryMsg=$(grep -F "$deliveryMessage" $i) #look for the delivery message in the file  
			deliveryTime=$(echo $deliveryMsg | awk '{print $4}')				
					
				output="$broadcastProcess,$messageId,$receivingProcess,$broadcastTime,$receivedTime,$deliveryTime"
				echo $output >> logdata.csv 
		done
	done
done
		 
sort -u logdata.csv| sort -t"," -k1,1 -k2,2n -o logdata.csv #sort logdata.csv so that the first column is sorted and then the second 

broadcasters=$(awk 'BEGIN {FS=","} {print $1}' logdata.csv|sort -u) #find the broadcasting processes 

receivers=$(awk 'BEGIN {FS=","} {print $3}' logdata.csv |sort -u) #find the receiving processes 
hReceivers=$(echo $receivers |sed 's/ /,/g') #add commas to receiving processes for header 
header="broadcaster,nummsgs,$hReceivers"  
echo $header > stats.csv

for broadcaster in $broadcasters
do     
	a=$(echo $broadcaster)
	numOfBroadcasts=$(grep -c "^$broadcaster" logdata.csv)
	numOfBroadcasts=$(expr $numOfBroadcasts / $count)
	b=$(echo $numOfBroadcasts)
	x=''	

	for receiver in $receivers
	do
		undeliveredMsgs=0 #keep track of messages being delivered 
		OLDIFS1="$IFS"
		IFS=$'\n' #change the IFS to newline so we can loop through lines 
		for line in $(grep "^$broadcaster" logdata.csv) #loop through all broadcast lines 
		do
			IFS=$OLDIFS1
			thisReceiver=$(echo $line | awk 'BEGIN {FS=","} {print $3}') #get the receiver and delivery time of this broadcast 
			thisDelivery=$(echo $line | awk 'BEGIN {FS=","} {print $NF}')

			if [[ "$thisReceiver" == "$receiver" ]] && [[ "$thisDelivery" == '' ]] 
			then
				undeliveredMsgs=$(expr $undeliveredMsgs + 1)
			fi 
		undeliveredMsgs2=$undeliveredMsgs
		done

	deliveredMsgs=$(expr $numOfBroadcasts - $undeliveredMsgs2) #the number of delivered messages is the number of broadcasts- undelivered messages 
	percentDelivered=$(echo "scale=4; $deliveredMsgs * 100 / $numOfBroadcasts"| bc) #the percentage of delivered messages is the delivered messages / broadcasts *100 
	
	c=$(echo $percentDelivered) 
	x+=$(echo -n "$c,") #a string of all the percentages delivered for each broadcast 
	done

y=$(echo "$x" |sed "s/ $//"|sed "s/,$//") #removing spaces and commas from the last percent entry for each broadcast 
echo "$a,$b,$y" >>stats.csv
done

echo "<HTML>" > stats.html 
echo "<BODY>" >> stats.html 
echo "<H2>GC Efficiency</H2>" >> stats.html
echo "<TABLE>" >> stats.html 

cat stats.csv| while read linez 
do 
	x="<TR><TH>"
	z="</TH></TR>"
	k="<TR><TD>"
	w="</TD></TR>"

	beginning=$(echo $linez | awk 'BEGIN {FS=","} {print $1}') #find the first word in the line 

	if [[ "$beginning" == "broadcaster" ]] #if the line is the header line 
	then 
		y=$(echo $linez | sed 's/,/<\/TH><TH>/g') #replace commas with header info 
		
		echo "$x$y$z" >>stats.html 

	else
		o=$(echo $linez | sed 's/,/<\/TD><TD>/g') #replace commas 
		
		echo "$k$o$w" >> stats.html 
	fi 
done

echo "</TABLE>" >> stats.html
echo "</BODY>" >> stats.html
echo "</HTML>" >> stats.html 

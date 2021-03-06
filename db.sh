#!/bin/bash
# echo "a.b.c.txt" | rev | cut -d"." -f2-  | rev
DELI='ourdb>'
dbDir=~/'.ourdb'
selectedDB=''
#init the server if it is not initialized before
function init {
	if ! [ -d $dbDir ];
	then
		mkdir $dbDir;
		cp ./help.txt ${dbDir}/.help.txt
		if [ $? = 0 ]; then
			echo -e "\e[ database server initialized create"
		else
			echo -e "\e[1;31;m error initializing the database server \e[0m"
			exit
		fi
	fi
}
#call init function
init

function createdb {
	if ! [ -d $dbDir ];then
		echo -e "\e[1;31m server error \e[0m"
	elif [[ $1 = "createdb" ]];then
		echo -e "\e[1;31m Error: you can use help command \e[0m"
	elif [ -n $1 ] && [ -d $dbDir/$1 ];then
		echo -e $1" \e[1;33m database aleady exists \e[0m"
	elif ! [[ $1 =~ ^[a-z]+[a-z0-9]*$ ]];then
		echo -e "\e[1;31m invalid database name, you can only use alphabet and number and start with character \e[0m"
	elif [ -d $dbDir ] && [ -n $1 ] ; then
		mkdir $dbDir/$1
		echo -e "\e[1;32m database $1 created \e[0m"
	else
		echo -e "\e[1;31m Error: you can use help command \e[0m"
	fi
}
#create table
#columns types (int, text, date)
#primary key

#createtable tablename ([col1_name col1_type, col2_name col2_type], primary key col_name)
function createTable {
	#echo "create data function"
	#echo $@
	if [ -d $dbDir ];
	then
		if [[ "$PWD" = */.ourdb/* ]]; then
			#table name
			if [[ -n $2 ]]; then

				if [[ $2 =~ ^[a-z]+[a-z0-9_]*$ ]];then
					#check if table exists
					if [ -f $2 ]; then
						echo -e "\e[1;31m Error: \e[0m Table $2 exists"
					else
					#check columns
					#echo $2

					echo "Please, Enter Columns Number"
					read -e cols_num
					
					if [[ $cols_num =~ ^[0-9]$ ]]; then
						echo -e "\e[1;33m Pay attention \e[0m Column Syntax <column_name>:null(y) or not null(n):<Column_type>"
						echo -e "\e[1;32m types \e[0m int, text, date"
						cols_str=()
						for (( i = 0; i< $cols_num; i++ ))
						do
							while [ true ]; do
								read -e -p "Column $((i+1)): " col
								#check for column systax
								if [[ $col =~ ^[a-zA-Z_]+:(n|N|y|Y):(int|text|date)$ ]]; then
									#check for column name
									if [[ `cut -d: -f1 <<< $col` =~ ^(int|text|date)$ ]]; then
										echo -e "\e[;31m invalid column name \e[0m" 
										continue
									fi				
									cols_str+=($col)
									break
								else
									echo -e "\e[1;31m Error: Invalid column systax \e[0m"
									continue
								fi
							done
						done
						#check if all columns entered in cols_str
						if [ $i -eq $cols_num ];then
							#write cols_number into table file 
							echo cols:$cols_num >> $2
							#write cols into table file
							for x in "${cols_str[@]}"
							do
								echo $x >> $2
							done
							echo -e "\e[1;32m Table Created.. \e[0m"
						else
							echo "operation aborted..."
						fi
					else
						echo -e "\e[1;31m Error: Invalid columns number \e[0m"
					fi
				fi
				else
					echo-e "\e[1;31m Error: table name must start with alphabet and not contains special character \e[0m"
				fi
			
			else
				echo -e "\e[1;31m Error: use help createtable \e[0m"
			fi
		else
			echo -e "\e[1;31m use database first : use <database name> \e[0m"
		fi
	else
		echo -e "\e[1;31m an error occured \e[0m"
	fi
}
function delete {
	if [ -d $dbDir ]; then
		#check command syntax
		if  [[ -n $1  &&  -n $2  &&  $1 != "delete"  && $2 =~ ^[a-z0-9_]+=[a-z0-9_]+$ ]];
		then
			#check using use command first
			if [[ "$PWD" = */.ourdb/* ]];then
				#check for table existance
				if [ -f $dbDir/*/$1 ]; then
					col="$(cut -d= -f1	<<< $2)"
					val="$(cut -d= -f2	<<< $2)"
					read cn <<< `sed '1!d' $1 | cut -d: -f2`
					# get table meta data (column name, column null or no, column type)
					for (( i=2 ; i <= $cn+1 ; i++ ))
					do
						col_arr+=(`sed "${i}!d" $selectedDB/$1` )
					done
					#check for col existance and get it is line number 
					#use it for determine which column to delete from
					for (( i=0; i < $cn; i++ ))
					do
						if [[ $col == `cut -d: -f1 <<< ${col_arr[i]}` ]];
						then
							col_num=$(( $i+1 ))
							break
						fi
					done

					#check for column existance
					if [ $col_num -gt 0 ];
					then
						let cn++
						#check for value existance and get it record number(record num with meta data lines)
						tmp=(`sed "1,${cn}d" $selectedDB/$1 | cut -d: -f$col_num | grep -xn "$val" | cut -d: -f1`)
						#check length of founded records
						# echo ${tmp[@]}
						# exit
						if [ ${#tmp[@]}  -gt 0 ];
						then
							#sed '${tmp[0]}d;${}'
							#loop for records
							tmp_2=""
							for (( i=0; i<${#tmp[@]}; i++ ))
							do
								tmp_2+=$((tmp[i]+cn))'d;'
							done
							sed -i "$tmp_2" $selectedDB/$1
							# tmp_file=`sed "$tmp_2" $selectedDB/$1`
							# echo $tmp_file > $selectedDB/$1
							echo -e "\e[1;32m ${#tmp[@]} Record(s) deleted \e[0m"
							
							#exit
						else
							echo -e "\e[1;31m record $col does not exist \e[0m"
						fi
					else
						echo -e "\e[1;31m Column name not found \e[0m"
					fi					
				else
					echo -e "\e[1;31m Table does not exist \e[0m"
				fi
			else
				echo -e "\e[1;31m You use select database first, command use <database_name> \e[0m"
			fi
		else
			echo -e "\e[1;31m command Error, use help command \e[0m"
		fi
	else
		echo -e "\e[1;31m Server Error \e[0m"
	fi
}

function update {
 
	if [ -d $dbDir ];
	then		
		if [[ "$PWD" = */.ourdb/* ]];then
			if [ -f $dbDir/*/$1 ]; then
				col="$(cut -d= -f1	<<< $2)"
				val="$(cut -d= -f2	<<< $2)"
				check=0
				check2=0
				count=0
				read cn <<< `sed '1!d' $1 | cut -d: -f2`
				let cn++
				# echo $cn
				for (( i=2 ; i <= $cn ; i++ ))
				do 
				
				 read col_tmp <<< $(sed "${i}!d"  $1 | cut -d: -f1)
			 	 if [[ $col = $col_tmp ]] 
				 then
				 check=1
				
				 let count=$i-1
					break;
				 fi
				done

				end=0
				end=$(wc -l $1 | cut -d ' ' -f1) 
				 
				   
				for (( i=$cn+1 ; i <= $end ; i++ ))
				do 
				
				 read val_tmp <<< $(sed "${i}!d"  $1 | cut -d: -f$count)
			 	 if [[ $val = $val_tmp ]] 
				 then
				 check2=1
				 
				 let count2=$i
					break;
				 
				 fi
				done
				#begin edit process if the col_name and col value is already exist
				if [[ $check -eq 1 && $check2 -eq 1 ]]
				then
				#  echo "I am checked"
				# echo "I am checked second"
				
				
 				#  sed "${count2}d"  $1 
				 tmpfile=`sed "${count2}d"  $1` 
				#  echo "$tmpfile"
		  		# echo "Please enter the values "
				
				# 
				col_arr=()
					#get columns name and type
					for (( i=2; i < $cn+1; i++ ))
					do
						col_arr+=(`sed "${i}!d" $selectedDB/$1` )
					done
						line=""
					for (( i=0; i < $cn - 1; i++ ))
					do
						col_name=$(cut -d: -f1 <<< ${col_arr[i]})
						col_null=$(cut -d: -f2 <<< ${col_arr[i]})
						col_type=$(cut -d: -f3 <<< ${col_arr[i]})
						tmp=$i
						echo "update $col_name:"
						
						read -e f
						#check for primary key in first column

						if [ $i -eq 0 ]; then
							tmp1=$(sed "1,${cn}d"  $selectedDB/$1 | cut -d: -f1 | grep -w $f)
							if [[ $tmp1 =~ ^[0-9]+$ ]];then
								echo -e "\e[1;31m Duplicated value: \e[0m $f value exists in column $col_name"
								let i--;
								continue
							fi
						fi
						case $col_type in 
							int)
								if [ col_null == 'n' ]; then
									if [[ $f =~ ^[0-9]+$ ]]; then
											line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								else
									if [[ $f =~ ^[0-9]*$ ]]; then
										line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								fi
								;;
							text)
								if [ col_null == 'n' ]; then
									if [[ "$f" =~ ^[a-z0-9[:space:]]+$ ]]; then
										line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								else
									if [[ "$f" =~ ^[a-z0-9[:space:]]*$ ]]; then
										line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								fi
								
								;;
							date)
								if [ col_null == 'n' ]; then
									if [[ $f =~ ^[0-3]?[0-9]{1}-[0|1]?[0-9]{1}-[0-9]{4}$ ]]; then
										line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								else
									if [[ -z $f ]] || [[ $f =~ ^[0-3]?[0-9]{1}-[0|1]?[0-9]{1}-[0-9]{4}$ ]]; then
										line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								fi
								;;
							*)
								echo -e "\e[1;31m server error \e[0m"
							;;
						esac
						
						#validation
						if [ $tmp == $i ]; then
							if [ $i -lt `expr $cn - 2` ]
							then
								line+=:
							fi
						fi
						

					done
					echo "$tmpfile" > $selectedDB/$1
					echo "$line" >> $selectedDB/$1
					

					# else
					# echo "col-name or col-value nt exist"
					fi

				else 
				echo -e "\e[1;31m Table name not exist \e[0m"
			fi
			#  echo $col_tmp
			#  echo $count
		else
			echo -e "\e[1;31m you should select database first \e[0m"
		fi
	else
		echo -e "\e[1;31m an error occured \e[0m"
	fi

}
function selecttable {
	if [ -d $dbDir ];
	then
		if [[ -n "$selectedDB" ]]; then
			if [[ -n $1 && $1 != 'selecttable' ]]; then
				#check file existance
				if [ -f  $selectedDB/$1 ]; then
					if [[ -n $2 ]]; then
						sed -n "/$2/p" $selectedDB/$1
					else
						#cn -> columns number
						read cn <<< `sed '1!d' $selectedDB/$1 | cut -d: -f2`
						let cn++
						
						col_arr=()
						for (( i=2; i < $cn+1; i++ ))
						do
							col_arr+=(`sed "${i}!d" $selectedDB/$1` )
						done
						if [ $(wc -l $selectedDB/$1 | cut -d ' ' -f1) -le $cn ]; then
							echo -e "\e[1;31mNothing to show \e[0m" 
						else
							for (( i=0; i < $cn - 1; i++ ))
							do
								col_name=$(cut -d: -f1 <<< ${col_arr[i]})
								col_null=$(cut -d: -f2 <<< ${col_arr[i]})
								col_type=$(cut -d: -f3 <<< ${col_arr[i]})
								printf "$col_name\t\t"
							done
							printf "\n======================================\n"	
							sed "1,${cn}d; s/:/\t\t/g" $selectedDB/$1
							# awk 'BEGIN {}' $selectedDB/$1
							echo
						fi
					fi
				else
					echo -e "\e[1;31m table does not exist \e[0m"
				fi
			else 
				echo -e "\e[1;31m invalid table name \e[0m"
			fi
		else
			echo -e "\e[1;31m you should select database first, or use help command \e[0m"
		fi	
	else
		echo -e "\e[1;31man error occured \e[0m"
	fi
}
#insert table_name
function insert {
	if [[ -n "$selectedDB" ]]; then
			if [[ -n $1 && $1 != 'insert' ]]; then
				if [ -f  $selectedDB/$1 ]; then
					#get columns numbers
					read cn <<< `sed '1!d' $selectedDB/$1 | cut -d: -f2`
					let cn++
					col_arr=()
					#get columns name and type
					for (( i=2; i < $cn+1; i++ ))
					do
						col_arr+=(`sed "${i}!d" $selectedDB/$1` )
					done
					# col_arr[0]
					# col_arr[1]
					# col_arr[2]
					line=""
					for (( i=0; i < $cn - 1; i++ ))
					do
						col_name=$(cut -d: -f1 <<< ${col_arr[i]})
						col_null=$(cut -d: -f2 <<< ${col_arr[i]})
						col_type=$(cut -d: -f3 <<< ${col_arr[i]})
						tmp=$i
						if [[ $col_type == "date" ]];then
							echo "insert $col_name (dd-mm-yyyy):"
						else
							echo "insert $col_name:"
						fi
						read -e f
						#check for primary key in first column

						if [ $i -eq 0 ]; then
							tmp1=$(sed "1,${cn}d"  $selectedDB/$1 | cut -d: -f1 | grep -w $f)
							if [[ $tmp1 =~ ^[0-9]+$ ]];then
								echo -e "\e[1;31m Duplicated value: \e[0m $f value exists in column $col_name"
								let i--;
								continue
							fi
						fi
						case $col_type in 
							int)
								if [ col_null == 'n' ]; then
									if [[ $f =~ ^[0-9]+$ ]]; then
											line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								else
									if [[ $f =~ ^[0-9]*$ ]]; then
										line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								fi
								;;
							text)
								if [ col_null == 'n' ]; then
									if [[ "$f" =~ ^[a-zA-Z0-9[:space:]]+$ ]]; then
										line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								else
									if [[ "$f" =~ ^[a-zA-Z0-9[:space:]]*$ ]]; then
										line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								fi
								
								;;
							date)
								if [ col_null == 'n' ]; then
									if [[ $f =~ ^[0-3]?[0-9]{1}-[0|1]?[0-9]{1}-[0-9]{4}$ ]]; then
										line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								else
									if [[ -z $f ]] || [[ $f =~ ^[0-3]?[0-9]{1}-[0|1]?[0-9]{1}-[0-9]{4}$ ]]; then
										line+=$f
									else
										echo -e "\e[1;31m TypeError: \e[0m invalid type for $col_name"
										let i--
									fi
								fi
								;;
							*)
								echo "server error"
							;;
						esac
						
						#validation
						if [ $tmp == $i ]; then
							if [ $i -lt `expr $cn - 2` ]
							then
								line+=:
							fi
						fi
						

					done
					echo $line >> $selectedDB/$1
					echo -e "\e[1;32m record inserted \e[0m"
				else
					echo -e "\e[1;31m invalid table name \e[0m"
				fi
			else
				echo -e "\e[1;31m invalid table name \e[0m"
			fi
	else
		echo -e "\e[1;31m syou should select database first, or use help command \e[0m"
	fi
}
function dropdb {
	if [ -n $1 ] && [ -d $dbDir/$1 ];then
		rm -r $dbDir/$1
		echo -e "\e[1;32m $1 has been deleted successfully \e[0m"
	else
		echo -e "\e[1;31m database $1 not exists. you can use help command \e[0m"
	fi
}
function showdb {
	if [ -d ${dbDir} ];
	then
		ls $dbDir
	else
		echo -e "\e[1;31m an error occured \e[0m"
	fi
}

function droptable {
	if [ -d $dbDir ];
	then		
		if [[ "$PWD" = */.ourdb/* ]];then
			if [ -f $dbDir/*/$1 ]; then
				rm $1
				echo -e "\e[1;32m table $1 deleted \e[0m"
			else
				echo -e "\e[1;31m table $1 does not exists \e[0m"
			fi
		else
			echo -e "\e[1;31m you should select database first \e[0m"
		fi
	else
		echo -e "\e[1;31m an error occured \e[0m"
	fi
}

function usedb {
	if [ -d $dbDir ];
	then
		# cd $dbDir
		if [ -n $1 ] && [ -d $dbDir/$1 ];then
			cd $dbDir/$1
			selectedDB=$dbDir/$1
			DELI=$1">"
			echo -e "\e[1;32m $1 now in used \e[0m"
		else
			echo -e "\e[1;31m database $1 does not exists \e[0m"
		fi
	else
		echo -e "\e[1;31m Server not initialized... \e[0m"
		#init
	fi
}
function showtables {
	if [ -d $dbDir ];
	then
		if [[ "$PWD" = */.ourdb/* ]]; then
			if [ $( ls | wc -l ) = 0 ];then
				echo -e "\e[1;31m no tables to show \e[0m" 
			else
				ls
			fi
		else
			echo -e "\e[1;31m use database first: use <database name> \e[0m"
		fi
	else
		echo -e "\e[1;31m an error occured \e[0m"
	fi
}
function whereme {
	if [ -d $dbDir ];
	then
		if [[ "$PWD" = */.ourdb/* ]]; then
			awk -F/ '{print $NF}' <<< $(pwd)
		else
			echo -e "\e[1;31muse database first : use <database name> \e[0m"
		fi
	else
		echo -e "\e[1;31man error occured \e[0m"
	fi
}

echo -e "\e[1;32mYou are logged into database engine\nYou can create database, Create table, Insert, Update or delete\n \e[0m"

while [  true ];
do
	
	read -p $DELI -e cmd

	string1="$(cut -d' '  -f1 <<< $cmd)"
	string2="$(cut -d' '  -f2 <<< $cmd)"
	string3="$(cut -d' '  -f3 <<< $cmd)"
	string4="$(cut -d' '  -f4 <<< $cmd)"
	string5="$(cut -d' '  -f5 <<< $cmd)"
	
	if [[ -z $cmd ]];
	then
		continue
	fi
	if [[ $string1 = 'createdb' ]];
	then
		createdb $string2
	elif [ $string1 = "createtable" ];then
		createTable ${cmd}
	elif [ $string1 = 'dropdb' ]; 
	then 
		dropdb $string2
	elif [ $string1 = 'show' ];
	then
		showdb
	elif [ $string1 = 'droptb' ];then
		droptable $string2
	elif [ $string1 = 'use' ];then
		usedb $string2
	
	elif [ $string1 = 'where' ];then
		whereme
	elif [ $string1 = 'showtables' ];then
		showtables
	elif [ $string1 = 'select' ];then
		#if [ -n $string3 ]; then
			selecttable $string2 $string3
		#else
		#	selecttable $string2 
		#fi
	elif [ $string1 = 'delete' ];then
		delete $string2 $string3
	elif [ $string1 = 'insert' ];then
		insert $string2 
	elif [ $string1 = 'update' ];then
	update $string2  $string3 
	elif [ $string1 = 'clear' ]; then
		clear
	elif [ $string1 = 'help' ]; then
		echo
		cat $dbDir"/.help.txt"
	elif [[ $string1 = "exit" ]]
	then
		echo "good bay";
		exit
	else
		echo -e "\e[1;31m invalid command \e[0m"
		#cat $dbDir/.help.txt
	fi
done

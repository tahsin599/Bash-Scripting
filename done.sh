#!/usr/bin/bash

archive_used=true
archive_used_i=""
allowed_archived_formats=""
allowed_languages=""
declare -i total_marks
declare -i penalty_unmatched_output
working_directory=""
student_id_range=""
expected_output_file_location=""
declare -i penalty_guideline_violations
plagiarism_file=""
declare -i plagiarism_penalty

filename=$2
echo "Processing file: $filename"
sed -i 's/\r//' $filename

lineno=1

while IFS= read -r line; do
    case $lineno in
        1)
           
            if [[ "$line" == "true" || "$line" == "false" ]]; then
                echo "First line is valid: $line"
            else
                echo "Invalid format in the first line: $line"
                exit 1
            fi
            ;;
        2)
            
            if [[ "$line" =~ ^[a-zA-Z0-9]+( [a-zA-Z0-9]+)*$ ]]; then
                echo "Second line is valid: $line"
            else
                echo "Invalid format in the second line: $line"
                exit 1
            fi
            ;;
        3)
            
            if [[ "$line" =~ ^[a-zA-Z]+( [a-zA-Z]+)*$ ]]; then
                echo "Third line is valid: $line"
            else
                echo "Invalid format in the third line: $line"
                exit 1
            fi
            ;;
        4)
            
            if [[ "$line" =~ ^[0-9]+$ ]]; then
                echo "Fourth line is valid: $line"
            else
                echo "Invalid format in the fourth line: $line"
                exit 1
            fi
            ;;
        5)
            # Check for the fifth line (integer)
            if [[ "$line" =~ ^[0-9]+$ ]]; then
                echo "Fifth line is valid: $line"
            else
                echo "Invalid format in the fifth line: $line"
                exit 1
            fi
            ;;
        6)
            
            if [[ "$line" =~ ^/*[^/]+(/[^/]+)*$ ]]; then
                echo "Sixth line is valid: $line"
            else
                echo "Invalid format in the sixth line: $line"
                exit 1
            fi
            ;;
        7)
            # Check for the seventh line (two integers)
            if [[ "$line" =~ ^[0-9]+[[:space:]][0-9]+$ ]]; then
                echo "Seventh line is valid: $line"
            else
                echo "Invalid format in the seventh line: $line"
                exit 1
            fi
            ;;
        8)
            
            if [[ "$line" =~ ^/*[^/]+(/[^/]+)*$ ]]; then
                echo "Eighth line is valid: $line"
            else
                echo "Invalid format in the eighth line: $line"
                exit 1
            fi
            ;;
        9)
            
            if [[ "$line" =~ ^[0-9]+$ ]]; then
                echo "Ninth line is valid: $line"
            else
                echo "Invalid format in the ninth line: $line"
                exit 1
            fi
            ;;
        10)
           
            if [[ "$line" =~ ^/*[^/]+(/[^/]+)*$ ]]; then
                echo "Tenth line is valid: $line"
            else
                echo "Invalid format in the tenth line: $line"
                exit 1
            fi
            ;;
     11)
            
            if [[ "$line" =~ ^[0-9]+$ ]]; then
                echo "Eleventh line is valid: $line"
            else
                echo "Invalid format in the eleventh line: $line"
                exit 1
            fi
            ;;
        *)
            echo "Unexpected number of lines in file."
            exit 1
            ;;
    esac
    
    # Increment the line counter
    ((lineno++))
done < "$filename"
lineno=1



while IFS= read -r line
do
    case $lineno in
        1) archive_used_i=$(echo "$line" | cut -d':' -f2 | xargs) ;;
        2) allowed_archived_formats=$(echo "$line" | cut -d':' -f2 | xargs) ;;
        3) allowed_languages=$(echo "$line" | cut -d':' -f2 | xargs) ;;
        4) total_marks=$(echo "$line" | cut -d':' -f2 | xargs) ;;
        5) penalty_unmatched_output=$(echo "$line" | cut -d':' -f2 | xargs) ;;
        6) working_directory=$(echo "$line" | cut -d':' -f2 | xargs) ;;
        7) student_id_range=$(echo "$line" | cut -d':' -f2 | xargs) ;;
        8) expected_output_file_location=$(echo "$line" | cut -d':' -f2 | xargs) ;;
        9) penalty_guideline_violations=$(echo "$line" | cut -d':' -f2 | xargs) ;;
        10) plagiarism_file=$(echo "$line" | cut -d':' -f2 | xargs) ;;
        11) plagiarism_penalty=$(echo "$line" | cut -d':' -f2 | xargs) ;;
    esac
    ((lineno++))
done < "$filename"
if [ "$archive_used_i" == "true" ];then
  archive_used=true
else
  archive_used=false  
fi

# Ensure directories exist
checked_dir="$working_directory/checked"
issues_dir="$working_directory/issues"

# Delete the directories if they already exist
rm -rf "$checked_dir" "$issues_dir"

# Recreate the directories
mkdir "$checked_dir" "$issues_dir"
echo "Student_ID,Marks,Marks_deducted,Total_Marks,Remarks" >> marks.csv
echo $working_directory
sed -i 's/\r//' $plagiarism_file

has_plagiarized() {
    local student_id="$1"
    
    # Check if the student_id is present in the plagiarism_file
    if grep -q -x "$student_id" "$plagiarism_file"; then
        
        return 0  
       
    else
        return 1  
    fi
}

for submission in $working_directory/*; do
    declare i case
    case=0
    declare -i result
    result=$total_marks
    echo "Processing submission: $submission"
    student_id=$(basename "$submission" | cut -d'.' -f1)

    if [[ "$submission" == "$plagiarism_file" || "$submission" == "$expected_output_file_location" ]]; then
        continue
    fi

    if [[ "$student_id" == "issues" || "$student_id" == "checked"  ]]; then
        continue
    fi
    echo $student_id
    echo ${student_id_range%% *}
    
    if [[ $student_id -lt ${student_id_range%% *} || $student_id -gt ${student_id_range##* } ]]; then
        echo "Student ID $student_id is out of range"
        echo "$student_id,0,$total_marks,$total_marks,issue case #5" >> marks.csv
        mv "$submission" "$issues_dir"
        continue
    fi

    
    if [[ "$archive_used" == true ]]; then
        
        if [[ -d "$submission" ]]; then
        echo "skipping archiving"
        case=1
        else
        extension="${submission##*.}"
        echo "File extension: $extension"
        
        if [[ ! "$allowed_archived_formats" =~ $extension ]]; then
            echo "$student_id has submitted an invalid archive format"
            echo "$student_id,0,$total_marks,$total_marks,issue case #2" >> marks.csv
            mv "$submission" "$issues_dir/"
            continue
        fi

        # Unarchive the submission
        mkdir -p "$working_directory/$student_id"
        if [ "$extension" == "zip" ]; then
            unzip -j "$submission" -d "$working_directory/$student_id"
        elif [ "$extension" == "tar" ]; then
            tar -xf "$submission" -C "$working_directory/$student_id"
        elif [ "$extension" == "rar" ]; then
            unrar x "$submission" "$working_directory/$student_id"
        fi
        fi

    else
        # If not archived, create student directory and move the file
        mkdir -p "$working_directory/$student_id"
        mv "$submission" "$working_directory/$student_id/"
    fi
    for submission_file in $working_directory/$student_id/*; do
    if [[ -d "$submission_file" ]]; then
    mv "$submission_file"/* "$submission_file"/..
    rm -rf "$submission_file"
    fi 
    

    # Check if the submission has the right programming language
    submission_id=$(basename "$submission_file" | cut -d'.' -f1)
    #submission_lang=$(basename "$submission_file" | cut -d'.' -f2)
    submission_lang=${submission_file##*.}
    echo "Submission language: $submission_lang"
    if [ $submission_lang = "py" ];then
            submission_lang="python"
    fi

    if [[ ! "$allowed_languages" =~ $submission_lang ]]; then
        echo "$student_id submitted in an invalid language"
        echo "$student_id,0,$total_marks,$total_marks,issue case #3" >> marks.csv
        mv "$working_directory/$student_id" "$issues_dir/"
        continue
    fi

   
    case "$submission_lang" in
        "c") gcc "$submission_file" -o "$working_directory/$student_id/${student_id}_output"
            if [ $? -eq 0 ]; then
              # Add execute permissions to the output binary
                chmod +x "$working_directory/$student_id/${student_id}_output"

                "$working_directory/$student_id/${student_id}_output" > "$working_directory/$student_id/${student_id}_output.txt"
            fi
        
        ;;
        "cpp") g++ "$submission_file" -o "$working_directory/$student_id/${student_id}_output"
            if [ $? -eq 0 ]; then
              # Add execute permissions to the output binary
                chmod +x "$working_directory/$student_id/${student_id}_output"

                "$working_directory/$student_id/${student_id}_output" > "$working_directory/$student_id/${student_id}_output.txt"
            fi
        
        ;;
        "python"|"py") python3 "$submission_file" > "$working_directory/$student_id/${student_id}_output.txt" ;;
        "sh") bash "$submission_file" > "$working_directory/$student_id/${student_id}_output.txt" ;;
    esac
    

    # Compare the output with the expected output
    output_file="$working_directory/$student_id/${student_id}_output.txt"
    sed -i 's/\r//' $output_file
    sed -i 's/\r//' $expected_output_file_location
    #total_lines=$(wc -l < "done2.txt")
    missing_lines=0


    while IFS= read -r line
    do
    
        if ! grep -Fxq "$line" "$output_file"; then
        
            ((missing_lines++))
        fi
    done < "$expected_output_file_location"

# Calculate the deducted marks
    has_plagiarized "$student_id"

# Check the result
    if [ $? -eq 0 ]; then
        plagiarism_deduction=$((total_marks * plagiarism_penalty / 100))
    
    # Calculate deduction for missing lines
        deducted_marks=$((missing_lines * penalty_unmatched_output))
    
    # Total deduction for both plagiarism and unmatched output
       total_deduction=$((plagiarism_deduction + deducted_marks))
    
    # Update the result after deduction
       result=$((total_marks - total_deduction))
    
    # Log the result in the marks.csv file
       
        def=$((total_marks - result))
       echo "$student_id,$result,$def,$total_marks,Has Plagiarized" >> marks.csv
    
    else
        deducted_marks=$((missing_lines * penalty_unmatched_output))
        result=$((result - deducted_marks))
    fi
    #diff_output=$(diff "$output_file" "$expected_output_file_location")
        #mismatch_count=diff "$output_file" "$expected_output_file_location" | grep "^!" | wc -l
    #if [ -z "$diff_output" ]; then
        #if [ "$mismatch_count" ==  "0" ]; then
        #declare -i def
        #def=$((total_marks - result))
        #echo "$student_id,$result,$def,$total_marks,Valid Submission" >> marks.csv
    #else
            
        #result=$((result - penalty_unmatched_output))
      
       # echo "$student_id,$result,$def,$total_marks,Unmatched output" >> marks.csv
    #fi
     
    if [[ "$submission_id" == "$student_id" ]]; then
       has_plagiarized "$student_id"

# Check the result
       if [ $? -eq 0 ]; then
           
           
            echo "no"
            
       else
            declare -i def 
           
            if [ $case -eq 1 ]; then
               result=$((result - penalty_guideline_violations))
               def=$((total_marks - result))
               echo "$student_id,$result,$def,$total_marks,Issue Case #1" >> marks.csv
            else
               def=$((total_marks - result))
               echo "$student_id,$result,$def,$total_marks,Valid Submission" >> marks.csv   
            fi
              
    
       fi
       mv "$working_directory/$student_id" "$checked_dir/"
       
    else
        declare -i def 
        result=$((result - penalty_guideline_violations))
        def=$((total_marks - result))

        echo "$student_id,$result,$def,$total_marks,Issue case #4" >> marks.csv
        mv "$working_directory/$student_id" "$checked_dir/"
    
    fi   
    continue
    
    
   
    done
done

range_start=${student_id_range%% *}
range_end=${student_id_range##* }

# Iterate through all student IDs in the range
for student_id_i in $(seq $range_start $range_end); do
    echo "Processing student ID: $student_id_i"
    
    # Check if student_id exists in marks.csv
    if ! grep -q "^$student_id_i," "marks.csv"; then
        
        echo "$student_id_i,0,$total_marks,$total_marks,No Submission" >> marks.csv
           
    
       
    fi
done

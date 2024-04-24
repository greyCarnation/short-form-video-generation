#!/bin/bash

avProcess() {

    videoFileName=$(cd 00_original && \ls *.mov)
    videoBasename=$(echo "$videoFileName" | sed 's/\..*//')
    audioFileName=$(cd 00_original && \ls *.mp3)
    audioBasename=$(echo "$audioFileName" | sed 's/\..*//')
    bpm=$(echo "$audioBasename" | sed 's/[^0-9]//g')
    audioDurationString=$(ffmpeg -i "00_original/${audioFileName}" 2>&1 | grep 'Duration:')
    audioDuration=$(echo "$audioDurationString" | sed -E 's/.*Duration: ([^,]+),.*/\1/')
    audioDurationSeconds=$(echo "$audioDuration" | sed 's/.*://')
    clipDuration=$(echo "scale=4; $audioDurationSeconds / 16" | bc)

  clearDirectories() {
    rm 01_conversion/* 02_clip/* 03_clipStage/* 04_mod/* 
  }
#
#  regenVideo() {
#    cd 03_clipStage || return 
#    shuf -n 14 clipStage.txt | sort -n > clipList_FINAL.txt
#    cat clipList.txt | head -1 | cat - clipList_FINAL.txt > temp && mv temp clipList_FINAL.txt
#    cat clipList.txt | tail -1 >> clipList_FINAL.txt
#    exit
#  }


  case $1 in
    create)
      if [ -z "$first" ]; then 
        first=9
      fi
      echo "video file basename is: ${videoBasename}"
      echo "audio bpm is: ${bpm}"
      echo "audio diration string is: ${audioDuration}"
      echo "audio diration is: ${audioDuration}"
      echo "audio diration seconds is: ${audioDurationSeconds} seconds"
      echo "clip duration is: ${clipDuration}" 

      cd 00_original || return
      ffmpeg -i "$videoFileName" -r 24 -c:v libx264 -x264opts keyint=2:min-keyint=2 -crf 19 -c:a copy -an "$videoBasename.mp4" 
      mv "$videoBasename.mp4" ../01_conversion/ 
      echo "" echo "converted original video to .mp4" | lolcat 
      echo "" 

      cd ../02_clip || return 
      ffmpeg -i "../01_conversion/$videoBasename.mp4" -c copy -f segment -segment_time "$clipDuration" -reset_timestamps 1 -sc_threshold 0 -g "$clipDuration" -force_key_frames "expr:gte(t, n_forced * ${clipDuration})" %04d_"$videoBasename"_clip.mp4
      clips=$(\ls)
      first_clip=$(echo "$clips" | head -1)
      last_clip=$(echo "$clips" | tail -1)
      rm "$first_clip" "$last_clip"
      \ls *.mp4 > ../03_clipStage/clipList.txt

      cd ../03_clipStage || return 
      numberOfClipsToOmit=$(($(cat clipList.txt | wc -l) - 14))
      echo "$numberOfClipsToOmit"
      sed '1d;$d' clipList.txt > clipStage.txt

      for i in $(seq 1 "$first"); do 
        shuf -n 14 clipStage.txt | sort -n > clipList_FINAL.txt
        cat clipList.txt | head -1 | cat - clipList_FINAL.txt > temp && mv temp clipList_FINAL.txt
        cat clipList.txt | tail -1 >> clipList_FINAL.txt
        
        cd ../04_mod || return 
        for clip in $(\cat ../03_clipStage/clipList_FINAL.txt);
        do 
          cp ../02_clip/"$clip" .
        done;
        sed "s/^/file '/g" ../03_clipStage/clipList_FINAL.txt > clipList_FINAL_formatted.txt
        sed "s/\$/\'/" clipList_FINAL_formatted.txt > clipList_FINAL_formatted_.txt
        mv clipList_FINAL_formatted_.txt clipList_FINAL_formatted.txt
        ffmpeg -y -f concat -i clipList_FINAL_formatted.txt -c copy "${videoBasename}_FINAL_woSound.mp4"
        ffmpeg -y -i "../00_original/$audioFileName" -i "${videoBasename}_FINAL_woSound.mp4" -c:v copy -c:a aac -shortest "${videoBasename}_FINAL_highFR.mp4" 
        ffmpeg -y -i "${videoBasename}_FINAL_highFR.mp4" -c copy -metadata keywords="draw,paint,drawing,painting,music,beat,artist,mhw,chill,cool,vibe,short" "../FINAL/${videoBasename}_drawing_painting_music_artist_short_${i}.mp4" 
        echo ""
        echo "FINAL video version no.$i was created" | lolcat
        echo ""
        cd ../03_clipStage || return
      done
      cd ../ || return

      echo "video file basename is: ${videoBasename}"
      echo "audio bpm is: ${bpm}"
      echo "audio diration string is: ${audioDuration}"
      echo "audio diration is: ${audioDuration}"
      echo "audio diration seconds is: ${audioDurationSeconds} seconds"
      echo "clip duration is: ${clipDuration}" 

      exit      
      ;;
    clean) 
      clearDirectories;
      exit
      ;;

    offload)
      if [ -z "$first" ]; then
        first=$(\ls 00_original/*.mov | sed 's/\..*//')
      fi
      mkdir "${first}_proj"
      cp -rv 00_original FINAL "${first}_proj" 
      mv "${first}_proj" ../_lib
      clearDirectories;
      rm 00_original/*
      exit

      ;;
    help) 
      echo "---avProcess---

Commands:
  clean
  offload
  create
  help
"
      exit
      ;;

  esac
}

avProcess "$1" "$first"

##################
# Main Functions #
##################

# How to install sox?
# MacOSX: http://sourceforge.net/projects/sox/files/sox/14.4.2/
# Linux: "sudo apt-get install sox"

PLAY () { # PLAY () {} Play audio file $1
    [ $play_hw != false ] && local play_export="AUDIODEV=$play_hw AUDIODRIVER=coreaudio" || local play_export=''
    eval "$play_export play -V1 -q $1";
}
LISTEN () { # LISTEN () {} Listens microhpone and record to audio file $1 when sound is detected until silence
    $verbose && local quiet='' || local quiet='-q'
    #[ $rec_hw != false ] && local rec_export="AUDIODEV=$rec_hw AUDIODRIVER=coreaudio" || local rec_export=''
    eval "$rec_export rec -V1 $quiet -r 16000 -c 1 -b 16 -e signed-integer --endian little $1 silence 1 $min_noise_duration_to_start $min_noise_perc_to_start 1 $min_silence_duration_to_stop $min_silence_level_to_stop trim 0 $max_noise_duration_to_kill"
}
STT () { # STT () {} Transcribes audio file $1 and writes corresponding text in $forder
if ([ "$bypass" == false ] && [ "$trigger_stt" == "pocketsphinx" ]) || ( "$bypass" && [ "$command_stt" == "pocketsphinx" ]); then
    LD_LIBRARY_PATH=/usr/local/lib PKG_CONFIG_PATH=/usr/local/lib/pkgconfig pocketsphinx_continuous -lm $language_model -dict $dictionary -logfn $pocketsphinxlog -infile $1 > $forder
else # using google
    json=`wget -q --post-file $1 --header="Content-Type: audio/l16; rate=16000" -O - "http://www.google.com/speech-api/v2/recognize?client=chromium&lang=$language&key=$google_speech_api_key"`
    $verbose && printf "DEBUG: $json\n"
    echo $json | perl -lne 'print $1 if m{"transcript":"([^"]*)"}' > $forder
fi
}
TTS () { # TTS () {} Speaks text $1
    if [[ "$platform" == "osx" ]]; then
        # MaxOSX: using built'in say function
        /usr/bin/say -v Daniel $1;
    else
        # Linux: using google translate speech synthesis if not cached already
        audio_file="$tmp_folder/`echo -n $1 | md5sum | awk '{print $1}'`.mp3"
        [ -f $audio_file ] || wget `$verbose || echo -q` -U Mozilla -O $audio_file "http://translate.google.com/translate_tts?tl=fr&client=tw-ob&ie=UTF-8&q=`rawurlencode \"$1\"`"
        mpg123 -q ` [ $play_hw = false ] || echo "-a $play_hw"` $audio_file # space between ` and [ is important
    fi
}

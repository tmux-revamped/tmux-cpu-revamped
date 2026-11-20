#!/bin/sh
# shellcheck disable=SC2034

[ -n "${CPU_REVAMPED_STATE_LOADED:-}" ] && return 0
CPU_REVAMPED_STATE_LOADED=1

CPU_REVAMPED_SETTINGS='popup_key	M-c
popup_width	80%
popup_height	80%
popup_command
interval	5
detail_interval	60
throttle_when_detached	0
render	jobs
medium_thresh	30
high_thresh	80
temp_medium_thresh	65
temp_high_thresh	80
load_medium_ratio	0.7
load_high_ratio	1.0
low_icon	▰▱▱
medium_icon	▰▰▱
high_icon	▰▰▰
low_fg_color
medium_fg_color
high_fg_color
low_bg_color
medium_bg_color
high_bg_color
temp_low_icon
temp_medium_icon
temp_high_icon
temp_low_fg_color
temp_medium_fg_color
temp_high_fg_color
temp_low_bg_color
temp_medium_bg_color
temp_high_bg_color
alert_icon	!
temp_unit	C
percentage_format	%s%%
temp_format
freq_format	%sMHz
load_format	%s
icons	ascii
fixed_width	off
percentage_label
temp_label
freq_label
load_label
load5_label
load15_label
count_label
graph_label
top_process_label
governor_label
percentage_width
temp_width
freq_width
load_width
load5_width
load15_width
count_width
graph_width
top_process_width
governor_width
cores_label
cores_width
sep_left	
sep_right	
sep_bg	default
throttle_icon	throttled
notify	0'
CPU_REVAMPED_NAMES='popup_key popup_width popup_height popup_command interval detail_interval throttle_when_detached render medium_thresh high_thresh temp_medium_thresh temp_high_thresh load_medium_ratio load_high_ratio low_icon medium_icon high_icon low_fg_color medium_fg_color high_fg_color low_bg_color medium_bg_color high_bg_color temp_low_icon temp_medium_icon temp_high_icon temp_low_fg_color temp_medium_fg_color temp_high_fg_color temp_low_bg_color temp_medium_bg_color temp_high_bg_color alert_icon temp_unit percentage_format temp_format freq_format load_format icons fixed_width percentage_label temp_label freq_label load_label load5_label load15_label count_label graph_label top_process_label governor_label percentage_width temp_width freq_width load_width load5_width load15_width count_width graph_width top_process_width governor_width cores_label cores_width sep_left sep_right sep_bg throttle_icon notify'
CPU_REVAMPED_CARRIED='popup_width popup_height popup_command interval detail_interval throttle_when_detached render medium_thresh high_thresh temp_medium_thresh temp_high_thresh load_medium_ratio load_high_ratio low_icon medium_icon high_icon low_fg_color medium_fg_color high_fg_color low_bg_color medium_bg_color high_bg_color temp_low_icon temp_medium_icon temp_high_icon temp_low_fg_color temp_medium_fg_color temp_high_fg_color temp_low_bg_color temp_medium_bg_color temp_high_bg_color alert_icon temp_unit percentage_format temp_format freq_format load_format icons fixed_width percentage_label temp_label freq_label load_label load5_label load15_label count_label graph_label top_process_label governor_label percentage_width temp_width freq_width load_width load5_width load15_width count_width graph_width top_process_width governor_width cores_label cores_width sep_left sep_right sep_bg throttle_icon notify'
CPU_REVAMPED_LIVE='percent temp freq load load5 load15 count top_process governor history percent_ts percent_lock percent_lock_ts temp_ts freq_ts load_ts top_process_ts governor_ts cores cores_stat cores_ts throttle throttle_count throttle_ts notified published'
CPU_REVAMPED_S_popup_key='M-c'
CPU_REVAMPED_S_popup_width='80%'
CPU_REVAMPED_S_popup_height='80%'
CPU_REVAMPED_S_popup_command=''
CPU_REVAMPED_S_interval='5'
CPU_REVAMPED_S_detail_interval='60'
CPU_REVAMPED_S_throttle_when_detached='0'
CPU_REVAMPED_S_render='jobs'
CPU_REVAMPED_S_medium_thresh='30'
CPU_REVAMPED_S_high_thresh='80'
CPU_REVAMPED_S_temp_medium_thresh='65'
CPU_REVAMPED_S_temp_high_thresh='80'
CPU_REVAMPED_S_load_medium_ratio='0.7'
CPU_REVAMPED_S_load_high_ratio='1.0'
CPU_REVAMPED_S_low_icon='▰▱▱'
CPU_REVAMPED_S_medium_icon='▰▰▱'
CPU_REVAMPED_S_high_icon='▰▰▰'
CPU_REVAMPED_S_low_fg_color=''
CPU_REVAMPED_S_medium_fg_color=''
CPU_REVAMPED_S_high_fg_color=''
CPU_REVAMPED_S_low_bg_color=''
CPU_REVAMPED_S_medium_bg_color=''
CPU_REVAMPED_S_high_bg_color=''
CPU_REVAMPED_S_temp_low_icon=''
CPU_REVAMPED_S_temp_medium_icon=''
CPU_REVAMPED_S_temp_high_icon=''
CPU_REVAMPED_S_temp_low_fg_color=''
CPU_REVAMPED_S_temp_medium_fg_color=''
CPU_REVAMPED_S_temp_high_fg_color=''
CPU_REVAMPED_S_temp_low_bg_color=''
CPU_REVAMPED_S_temp_medium_bg_color=''
CPU_REVAMPED_S_temp_high_bg_color=''
CPU_REVAMPED_S_alert_icon='!'
CPU_REVAMPED_S_temp_unit='C'
CPU_REVAMPED_S_percentage_format='%s%%'
CPU_REVAMPED_S_temp_format=''
CPU_REVAMPED_S_freq_format='%sMHz'
CPU_REVAMPED_S_load_format='%s'
CPU_REVAMPED_S_icons='ascii'
CPU_REVAMPED_S_fixed_width='off'
CPU_REVAMPED_S_percentage_label=''
CPU_REVAMPED_S_temp_label=''
CPU_REVAMPED_S_freq_label=''
CPU_REVAMPED_S_load_label=''
CPU_REVAMPED_S_load5_label=''
CPU_REVAMPED_S_load15_label=''
CPU_REVAMPED_S_count_label=''
CPU_REVAMPED_S_graph_label=''
CPU_REVAMPED_S_top_process_label=''
CPU_REVAMPED_S_governor_label=''
CPU_REVAMPED_S_percentage_width=''
CPU_REVAMPED_S_temp_width=''
CPU_REVAMPED_S_freq_width=''
CPU_REVAMPED_S_load_width=''
CPU_REVAMPED_S_load5_width=''
CPU_REVAMPED_S_load15_width=''
CPU_REVAMPED_S_count_width=''
CPU_REVAMPED_S_graph_width=''
CPU_REVAMPED_S_top_process_width=''
CPU_REVAMPED_S_governor_width=''
CPU_REVAMPED_S_cores_label=''
CPU_REVAMPED_S_cores_width=''
CPU_REVAMPED_S_sep_left=''
CPU_REVAMPED_S_sep_right=''
CPU_REVAMPED_S_sep_bg='default'
CPU_REVAMPED_S_throttle_icon='throttled'
CPU_REVAMPED_S_notify='0'
CPU_REVAMPED_S_percent=''
CPU_REVAMPED_S_temp=''
CPU_REVAMPED_S_freq=''
CPU_REVAMPED_S_load=''
CPU_REVAMPED_S_load5=''
CPU_REVAMPED_S_load15=''
CPU_REVAMPED_S_count=''
CPU_REVAMPED_S_top_process=''
CPU_REVAMPED_S_governor=''
CPU_REVAMPED_S_history=''
CPU_REVAMPED_S_percent_ts=''
CPU_REVAMPED_S_percent_lock=''
CPU_REVAMPED_S_percent_lock_ts=''
CPU_REVAMPED_S_temp_ts=''
CPU_REVAMPED_S_freq_ts=''
CPU_REVAMPED_S_load_ts=''
CPU_REVAMPED_S_top_process_ts=''
CPU_REVAMPED_S_governor_ts=''
CPU_REVAMPED_S_cores=''
CPU_REVAMPED_S_cores_stat=''
CPU_REVAMPED_S_cores_ts=''
CPU_REVAMPED_S_throttle=''
CPU_REVAMPED_S_throttle_count=''
CPU_REVAMPED_S_throttle_ts=''
CPU_REVAMPED_S_notified=''
CPU_REVAMPED_S_published=''
CPU_REVAMPED_METRICS='percentage icon fg_color bg_color temp temp_icon temp_fg_color temp_bg_color freq load load5 load15 count graph top_process governor load_color alert cores sep_left sep_right throttle'
CPU_REVAMPED_LABELLED='percentage temp freq load load5 load15 count graph top_process governor cores'
CPU_REVAMPED_DEFAULT_POPUP_KEY='M-c'
CPU_REVAMPED_DEFAULT_INTERVAL=5
CPU_REVAMPED_DEFAULT_DETAIL=60
CPU_REVAMPED_DEFAULT_GRAPH=20
CPU_REVAMPED_DEFAULT_MEDIUM=30
CPU_REVAMPED_DEFAULT_HIGH=80
CPU_REVAMPED_DEFAULT_TEMP_MEDIUM=65
CPU_REVAMPED_DEFAULT_TEMP_HIGH=80
CPU_REVAMPED_GRAPH_STEPS=8
CPU_REVAMPED_GRAPH_DIVISOR=101
CPU_REVAMPED_POPUP_SINCE=3.2
CPU_REVAMPED_NOTES_SINCE=3.1
CPU_REVAMPED_SAMPLE=0.3
CPU_REVAMPED_JXA='ObjC.import("Foundation");ObjC.bindFunction("mach_host_self",["unsigned int",[]]);ObjC.bindFunction("host_processor_info",["int",["unsigned int","int","unsigned int *","void **","unsigned int *"]]);var n=Ref(),p=Ref(),c=Ref(),o="";if($.host_processor_info($.mach_host_self(),2,n,p,c)===0){var d=$.NSData.dataWithBytesLength(p[0],c[0]*4);for(var i=0;i<n[0];i++){var h=ObjC.unwrap(d.subdataWithRange($.NSMakeRange(i*16,16)).description).split("0x")[1];var f=[];for(var k=0;k<4;k++){var s=h.substr(k*8,8);f.push(parseInt(s.substr(6,2)+s.substr(4,2)+s.substr(2,2)+s.substr(0,2),16))}o+="cpu"+i+" "+f[0]+" "+f[3]+" "+f[1]+" "+f[2]+"\n"}}o'
CPU_REVAMPED_SYS=/sys
CPU_REVAMPED_EMPTY='cpu-revamped-empty-argument'
CPU_REVAMPED_MARK='cpu-revamped-section:'
CPU_REVAMPED_TMUX=''
CPU_REVAMPED_NOTES=0
CPU_REVAMPED_TOOL=''
CPU_REVAMPED_JOB=''
CPU_REVAMPED_KEYS=''
CPU_REVAMPED_SKIPPED=''
CPU_REVAMPED_PLAN=''
CPU_REVAMPED_NOW=0
CPU_REVAMPED_LIMIT=5
CPU_REVAMPED_DETAIL=60
CPU_REVAMPED_NUMBER=0
CPU_REVAMPED_DOUBLED=''
CPU_REVAMPED_WANT=''
CPU_REVAMPED_RAW=''
CPU_REVAMPED_DUE=''
CPU_REVAMPED_LINE=''
CPU_REVAMPED_POPUP_OK=0
CPU_REVAMPED_STORED=0
CPU_REVAMPED_TIER='low'
CPU_REVAMPED_OUT=''
CPU_REVAMPED_LABEL=''
CPU_REVAMPED_WIDTH=''
CPU_REVAMPED_GLYPH=''
CPU_REVAMPED_NATURAL=0
CPU_REVAMPED_MONITOR=''
CPU_REVAMPED_CARD=''
CPU_REVAMPED_F_percent=''
CPU_REVAMPED_F_temp=''
CPU_REVAMPED_F_freq=''
CPU_REVAMPED_F_load=''
CPU_REVAMPED_F_load5=''
CPU_REVAMPED_F_load15=''
CPU_REVAMPED_F_count=''
CPU_REVAMPED_F_governor=''
CPU_REVAMPED_F_top_process=''
CPU_REVAMPED_F_history=''
CPU_REVAMPED_F_cores=''
CPU_REVAMPED_F_cores_stat=''
CPU_REVAMPED_F_throttle=''
CPU_REVAMPED_F_throttle_count=''
REVAMPED_CACHE_PREFIX=cpu_revamped
CPU_REVAMPED_KINDS='interval	number
detail_interval	number
graph_width	number
medium_thresh	number
high_thresh	number
temp_medium_thresh	number
temp_high_thresh	number
percentage_width	number
temp_width	number
freq_width	number
load_width	number
load5_width	number
load15_width	number
count_width	number
top_process_width	number
governor_width	number
throttle_when_detached	0 1
render	jobs options
icons	ascii nerd
fixed_width	on off
temp_unit	C F
cores_width	number
notify	0 1'

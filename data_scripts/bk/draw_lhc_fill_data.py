import sys
import numpy as np
import pandas as pd
import requests
import json
import argparse
import re
import os
import datetime
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib import gridspec

import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

#Daiki Sekihata, the University of Tokyo
#daiki.sekihata@cern.ch

#run like this: python draw_lhc_fill_data.py -f 9548 -t 9562 -c pp -e 13.6;

parser = argparse.ArgumentParser('a script to download ALICE run info from https://ali-bookkeeping.cern.ch/api/runs');
parser.add_argument("-f", "--From", default=0, type=int, help="desired fill number from this value", required=True)
parser.add_argument("-t", "--To"  , default=99999 , type=int, help="desired fill number up to this value", required=True)
parser.add_argument("-c", "--Collision"  , default="pp" , type=str, help="collision system [pp, PbPb, pPb, Pbp, OO, pO, etc]", required=True)
parser.add_argument("-e", "--Energy"  , default="13.6" , type=str, help="collision energy in TeV", required=True)
parser.add_argument("-s", "--Suffix"  , default="" , type=str, help="suffix for plots (e.g. week number)", required=False)
args = parser.parse_args();

#_____________________________________________________________________________________
def plot_run_duration_per_detector(df, collsys, energy, suffix):
    list_det = [
        "CPV", "EMC", "FDD", "FT0", "FV0",
        "HMP", "ITS", "MCH", "MFT", "MID",
        "PHS", "TOF", "TPC", "TRD", "ZDC"
    ];
    ndet = len(list_det);
    lefts = np.arange(ndet)

    nrun = 0;

    list_duration_good_det = [0.0 for i in range(0,ndet)];
    list_duration_bad_det  = [0.0 for i in range(0,ndet)];
    list_duration_test_det = [0.0 for i in range(0,ndet)];
    list_duration_none_det = [0.0 for i in range(0,ndet)];
    list_nrun_det = [0 for i in range(0,ndet)];

    for index, run in df.iterrows():
        timeh = float(run["runDuration"]) /3600./1e+3;#convert mili second to hour
        detname_1d = run["detectors"];
        det_quality_1d = run["detectorsQualities"];
        #print(det_quality_1d);
        if run["definition"] != "PHYSICS": #this is global run quality
            continue;
        if run["runQuality"] == "bad": #this is global run quality
            continue;
        nrun += 1;

        list_run_det = [j for j in detname_1d.split(',')];
        #print(list_run_det,len(list_run_det));

        for idet in range(0, len(list_run_det)):
            idx = list_det.index(list_run_det[idet]);
            list_nrun_det[idx] += 1;
            run_quality_per_det = run["detectorsQualities"][idet]['quality'];
            if run_quality_per_det == "good":
                list_duration_good_det[idx] += timeh;
            elif run_quality_per_det == "bad":
                list_duration_bad_det[idx] += timeh;
            elif run_quality_per_det == "test":
                list_duration_test_det[idx] += timeh;
            else:
                list_duration_none_det[idx] += timeh;

    y1 = np.array(list_duration_good_det, dtype=float);
    y2 = np.array(list_duration_good_det, dtype=float) + np.array(list_duration_bad_det, dtype=float);
    y3 = np.array(list_duration_good_det, dtype=float) + np.array(list_duration_bad_det, dtype=float) + np.array(list_duration_test_det, dtype=float);
    y4 = np.array(list_duration_good_det, dtype=float) + np.array(list_duration_bad_det, dtype=float) + np.array(list_duration_test_det, dtype=float) +  + np.array(list_duration_none_det, dtype=float);
    y_max = max(y4);

    print("total number of run = ",nrun);
    mpl.rcParams['axes.xmargin'] = 0;
    fig = plt.figure(figsize=(10, 10),dpi=100);

    plt.bar(lefts, list_duration_good_det, tick_label=list_det, align="center", label="good", color="green");
    plt.bar(lefts, list_duration_bad_det , tick_label=list_det, align="center", label="bad" , color="red"   , bottom=y1);
    plt.bar(lefts, list_duration_test_det, tick_label=list_det, align="center", label="test", color="orange", bottom=y2);
    plt.bar(lefts, list_duration_none_det, tick_label=list_det, align="center", label="none", color="grey", bottom=y3);
    plt.xticks(rotation=0, fontsize=18);
    plt.yticks(rotation=0, fontsize=18);
    plt.xlabel('detector', fontsize=18)
    plt.ylabel('running time (hour)', fontsize=18)
    plt.grid(axis='y');
    plt.ylim(0, y_max * 1.15);
    legend = plt.legend(title="running time in globally good physics runs", frameon=False, handletextpad=0.0, fontsize=16, borderpad=0.5, labelspacing=0.1, loc='upper left', ncol=2)
    plt.setp(legend.get_title(),fontsize=18)

    plt.subplots_adjust(left=0.08, right=0.99, top=0.99, bottom=0.06)
    date = datetime.date.today().strftime("%Y%m%d");
    plt.savefig("/home/rc/lhc-fill-plotter/{0}_run_duration_per_detector_{1}_{2}{3}.eps".format(date, collsys, energy, suffix), format="eps",dpi=400);
    plt.savefig("/home/rc/lhc-fill-plotter/{0}_run_duration_per_detector_{1}_{2}{3}.pdf".format(date, collsys, energy, suffix), format="pdf",dpi=400);
    plt.savefig("/home/rc/lhc-fill-plotter/{0}_run_duration_per_detector_{1}_{2}{3}.png".format(date, collsys, energy, suffix), format="png",dpi=400);
    #plt.show();

#_____________________________________________________________________________________
def plot_run_duration(df, collsys, energy, suffix):
    list_fill_number = [];
    list_run_number = [];
    list_duration = [];
    list_color = [];
    for index, fill in df.iterrows():
        for run in fill['runs']: # loop over list of DF
            if run['definition'] != 'PHYSICS':
                continue;
            print("run number {0} : quality = {1} , nDetectors = {2}".format(run['runNumber'], run['runQuality'], run['nDetectors']));
            list_fill_number.append(int(fill['fillNumber']));
            list_run_number.append(int(run['runNumber']));
            list_duration.append(float(run['runDuration']) /3600./1e+3);#convert mili second to hour
            if run['runQuality'] == "good":
                list_color.append("green");
            elif run['runQuality'] == "bad":
                list_color.append("red");
            elif run['runQuality'] == "test":
                list_color.append("orange");
            else:
                list_color.append("grey");

    #print(list_fill_number);
    #print(list_run_number);
    #print(list_duration);
    y_max = 1.22 * max(list_duration);

    mpl.rcParams['axes.xmargin'] = 0;
    fig = plt.figure(figsize=(16,8),dpi=100);
    lefts = np.arange(len(list_run_number))
    plt.bar(lefts, list_duration, tick_label=list_run_number, align="center", color=list_color);
    plt.xticks(rotation=90,fontsize=18)
    plt.yticks(np.arange(0, y_max, 1.0), rotation=0, fontsize=18)
    plt.xlabel('run number', fontsize=18)
    plt.ylabel('run duration (hour)', fontsize=18)
    plt.ylim(0, y_max);
    plt.grid(axis='y');

    nrun = len(list_run_number);
    print("total number of physics run = ", nrun);

    for j in range(0, nrun-1):
        if list_fill_number[j] != list_fill_number[j+1]:
            plt.vlines(j+0.5, 0, y_max, 'black', 'solid');
            plt.text(j+0.0, y_max*0.84, 'Fill {0}'.format(list_fill_number[j]), rotation=90, fontsize=18);
        if j == nrun-2:
            plt.vlines(j+1.5, 0, y_max, 'black', 'solid');
            plt.text(j+1.0, y_max*0.84, 'Fill {0}'.format(list_fill_number[j]), rotation=90, fontsize=18);
    plt.subplots_adjust(left=0.05, right=0.995, top=0.99, bottom=0.18)

    plt.plot([], [], marker="s", color="green", label="good", linestyle="none")
    plt.plot([], [], marker="s", color="red"  , label="bad", linestyle="none")
    plt.plot([], [], marker="s", color="orange"  , label="test", linestyle="none")
    plt.plot([], [], marker="s", color="grey"  , label="none", linestyle="none")
    legend = plt.legend(frameon=False, handletextpad=0.0,fontsize=18, borderpad=0.5, labelspacing=0.1, loc='upper left')

    date = datetime.date.today().strftime("%Y%m%d");
    plt.savefig("{0}_run_duration_{1}_{2}TeV{3}.eps".format(date, collsys, energy, suffix), format="eps",dpi=400);
    plt.savefig("{0}_run_duration_{1}_{2}TeV{3}.pdf".format(date, collsys, energy, suffix), format="pdf",dpi=400);
    plt.savefig("{0}_run_duration_{1}_{2}TeV{3}.png".format(date, collsys, energy, suffix), format="png",dpi=400);
    #plt.show()
#_____________________________________________________________________________________
def plot_lhc_fill(df, collsys, energy, suffix=""):
    print(sys._getframe().f_code.co_name);
    nfill = len(df);
    print("total number of fills = ", nfill);
    #df = df.iloc[::-1];

    list_fill_number = [];
    list_sb_duration = [];
    list_sb_starttime = [];
    list_sb_endtime = [];
    list_filling_scheme = [];
    list_run_number = [];
    list_run_quality = [];
    list_run_duration_bad = [];
    list_run_starttime = [];
    list_run_endtime = [];
    list_efficiency = [];
    list_total_run_duration_good = [];
    list_total_run_duration_bad = [];
    list_time_before_1st_run = [];
    list_time_after_last_run = [];
    list_time_between_runs = [];

    for i, fill in df.iterrows():
        print("Stable Beam Duration=",fill['stableBeamsDuration']);
        if fill['stableBeamsDuration'] > 0 :
            list_sb_starttime.append(fill['stableBeamsStart']/1e+3/3600.); #epoch mili second -> hour
            list_sb_endtime.append(fill['stableBeamsEnd']/1e+3/3600.); #epoch mili second -> hour
            list_sb_duration.append(fill['stableBeamsDuration']/3600.); #epoch second -> hour, stable beam duration is stored in second.
            list_fill_number.append(fill['fillNumber']);
            list_filling_scheme.append(fill['fillingSchemeName']);

            nrun = len(fill['runs']);
            print("{0} runs in fill number {1}".format(nrun, fill['fillNumber']));

            #run info
            #print(fill['runs']);
            list_run_number_tmp = [];
            list_run_quality_tmp = [];
            list_run_starttime_tmp = [];
            list_run_endtime_tmp = [];
            sb_duration = fill['stableBeamsDuration']/3600; #stable beam duration is stored in second.
            alice_run_duration_good = 0;
            alice_run_duration_bad = 0;
            for run in fill['runs']: # loop over list of DF
                if run['definition'] != 'PHYSICS':
                    continue;
                print("run number {0} : quality = {1} , nDetectors = {2}".format(run['runNumber'], run['runQuality'], run['nDetectors']));
                list_run_number_tmp.append(run['runNumber']);
                list_run_quality_tmp.append(run['runQuality']);
                list_run_starttime_tmp.append(run['startTime']/1e+3/3600.); #in epoch UTC -> hour
                list_run_endtime_tmp.append(run['endTime']/1e+3/3600.); #in epoch UTC -> hour
                if run['runQuality'] == 'good' or run['runQuality'] == 'test':
                    alice_run_duration_good += run['runDuration']/1e+3/3600.;
                elif run['runQuality'] == 'bad' or run['runQuality'] == 'none':
                    alice_run_duration_bad += run['runDuration']/1e+3/3600.;

            list_total_run_duration_good.append(alice_run_duration_good);
            list_total_run_duration_bad.append(alice_run_duration_bad);
            list_run_number.append(list_run_number_tmp);
            list_run_quality.append(list_run_quality_tmp);
            list_run_starttime.append(list_run_starttime_tmp);
            list_run_endtime.append(list_run_endtime_tmp);

            if nrun > 0.5:
                list_time_before_1st_run.append(list_run_starttime[-1][0] - fill['stableBeamsStart']/1e+3/3600);
                if fill['stableBeamsEnd']/1e+3/3600 > list_run_endtime[-1][-1]:
                    list_time_after_last_run.append(fill['stableBeamsEnd']/1e+3/3600 > list_run_endtime[-1][-1]);
                else:
                    list_time_after_last_run.append(0);
            else:
                list_time_before_1st_run.append(0);
                list_time_after_last_run.append(0);

            if sb_duration > 0:
                list_efficiency.append(float(alice_run_duration_good)/float(sb_duration) * 100);
            else:
                list_efficiency.append(0.0);

            time_between_runs = sb_duration - (alice_run_duration_good + alice_run_duration_bad + list_time_before_1st_run[-1] + list_time_after_last_run[-1]);
            list_time_between_runs.append(time_between_runs);

    #print(list_run_number);
    #print(list_run_starttime);
    #print(list_run_endtime);
    #print(list_sb_duration);
    #print(list_efficiency);
    #print(list_time_before_1st_run);
    #print(list_time_after_last_run);
    
    mpl.rcParams['axes.xmargin'] = 0;
    fig = plt.figure(figsize=(18,8),dpi=100);
    gs = gridspec.GridSpec(2,1);#starting from top
    ax0 = plt.subplot(gs[0]);
    ax1 = plt.subplot(gs[1], sharex=ax0);
    lefts = np.arange(len(list_fill_number))

    ax0.plot(lefts, list_efficiency, label="", marker="o", color='green');
    #ax1.bar(lefts, list_sb_duration     , tick_label=list_fill_number, align="edge", width=-0.4, label="stable beam duration", color='blue');
    #ax1.bar(lefts, list_total_run_duration_good, tick_label=list_fill_number, align="edge", width=+0.4, label="ALICE running time", color='green');

    for i, value in enumerate(list_efficiency):
        ax0.text(lefts[i] - 0.1, list_efficiency[i] + 2.0, "{0:2.1f}%".format(value), fontsize=13)

    bottom1 = np.array(list_total_run_duration_good, dtype=float);
    bottom2 = np.array(list_total_run_duration_good, dtype=float) + np.array(list_total_run_duration_bad, dtype=float);
    bottom3 = np.array(list_total_run_duration_good, dtype=float) + np.array(list_total_run_duration_bad, dtype=float) + np.array(list_time_before_1st_run, dtype=float);
    bottom4 = np.array(list_total_run_duration_good, dtype=float) + np.array(list_total_run_duration_bad, dtype=float) + np.array(list_time_before_1st_run, dtype=float) + np.array(list_time_after_last_run, dtype=float);

    ax1.bar(lefts, list_sb_duration            , tick_label=list_fill_number, align="edge", width=-0.4, color="blue"  , label="stable beam duration");
    ax1.bar(lefts, list_total_run_duration_good, tick_label=list_fill_number, align="edge", width=+0.4, color="green" , label="ALICE running time (good)");
    ax1.bar(lefts, list_total_run_duration_bad , tick_label=list_fill_number, align="edge", width=+0.4, color="red"   , label="ALICE running time (bad)"   , bottom = bottom1);
    ax1.bar(lefts, list_time_before_1st_run    , tick_label=list_fill_number, align="edge", width=+0.4, color="orange"   , label="time before 1st run", bottom = bottom2);
    ax1.bar(lefts, list_time_after_last_run    , tick_label=list_fill_number, align="edge", width=+0.4, color="purple", label="time after last run"   , bottom = bottom3);
    ax1.bar(lefts, list_time_between_runs      , tick_label=list_fill_number, align="edge", width=+0.4, color="magenta", label="time between runs"         , bottom = bottom4);

    ax1.set_xlabel('fill number', fontsize=20)
    ax0.set_ylabel('efficiency (%)', fontsize=20)
    ax1.set_ylabel('duration (hour)', fontsize=20)

   # ax0.set_yticks([0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100])
    ax0.set_yticks([50, 60, 70, 80, 90, 100])
    ax0.set_ylim([45, 105]);
    y_max = int(max(list_sb_duration)) * 1.5;
    ax1.set_ylim([0, y_max]);
    ax1.set_yticks(np.arange(0, y_max, 2.0))

    ax0.grid(axis='both');
    ax1.grid(axis='both');

    if "pp" in collsys:
        ax1.legend(title="{0} at $\\sqrt{{s}}$ = {1} TeV".format(collsys, energy), fontsize=16, title_fontsize=15, loc='upper left', ncol=3);
    else :
        ax1.legend(title="{0} at $\\sqrt{{s_{{NN}}}}$ = {1} TeV".format(collsys, energy), fontsize=15, title_fontsize=15, loc='upper left', ncol=3);
    ax0.tick_params(labelsize=18);
    ax1.tick_params(labelsize=18);

    plt.subplots_adjust(hspace=.0)
    plt.subplots_adjust(left=0.055, right=0.995, top=0.99, bottom=0.14)

    #for i in range(0, len(list_sb_duration)):
    #    ax1.text(i-0.25, max(list_sb_duration) * 1.05, '{0}'.format(list_filling_scheme[i].replace("b_","b_\n").replace("bpi_", "bpi_\n")), rotation=90, fontsize=14);

    plt.setp(ax0.get_xticklabels(), visible=False)
    plt.xticks(rotation=90,fontsize=18)

    date = datetime.date.today().strftime("%Y%m%d");
    #plt.savefig("~/lhc_fill_plotter/{0}_LHC_fill_data_{1}_{2}TeV{3}.eps".format(date, collsys, energy, suffix), format="eps",dpi=400);
    #plt.savefig("~/lhc_fill_plotter/{0}_LHC_fill_data_{1}_{2}TeV{3}.pdf".format(date, collsys, energy, suffix), format="pdf",dpi=400);
    plt.savefig("/home/rc/lhc-fill-plotter/{0}_LHC_fill_data_{1}_{2}TeV{3}.png".format(date, collsys, energy, suffix), format="png",dpi=400);
    #plt.show();
#_____________________________________________________________________________________
def extract_alice_data_from_bookkeeping(filename):
    #create json file
    token = os.environ["BK_TOKEN"];
    print(token);
    req = requests.get('https://ali-bookkeeping.cern.ch/api/runs?token='+token, verify=False);
    data = json.loads(req.text)['data'];
    with open (filename, 'w') as f:
        json.dump(data, f, indent=2);
#_____________________________________________________________________________________
def extract_lhc_data_from_bookkeeping(filename):
    #create json file
    token = os.environ["BK_TOKEN"];
    print(token);
    req = requests.get('https://ali-bookkeeping.cern.ch/api/lhcfills?token='+token, verify=False);
    data = json.loads(req.text)['data'];
    with open (filename, 'w') as f:
        json.dump(data, f, indent=2);
#_____________________________________________________________________________________
def read_json(filename):
    json_open = open(filename, 'r');
    data = json.load(json_open);
    return data;
#_____________________________________________________________________________________
if __name__ == "__main__":
    filename_lhc   = 'lhc_fill_data.json';
    filename_alice = 'alice_run_data.json';
    extract_lhc_data_from_bookkeeping(filename_lhc);
    extract_alice_data_from_bookkeeping(filename_alice);

    fill_from = args.From;
    fill_to = args.To;
    suffix = args.Suffix;
    collsys = args.Collision; #collision system
    energy = args.Energy; #collision energy

    data_lhc = read_json(filename_lhc);
    df_lhc_all = pd.json_normalize(data_lhc);
    df_lhc = df_lhc_all[(fill_from <= df_lhc_all['fillNumber']) & (df_lhc_all['fillNumber'] <= fill_to)];
    df_lhc = df_lhc.iloc[::-1]; #sorted by increasing order
    plot_lhc_fill(df_lhc, collsys, energy, suffix);
    plot_run_duration(df_lhc, collsys, energy, suffix);

    data_alice = read_json(filename_alice);
    df_alice_all = pd.json_normalize(data_alice);
    df_alice = df_alice_all[(fill_from <= df_alice_all['fillNumber']) & (df_alice_all['fillNumber'] <= fill_to)];
    df_alice = df_alice.iloc[::-1]; #sorted by increasing order
    plot_run_duration_per_detector(df_alice, collsys, energy, suffix);

#_____________________________________________________________________________________

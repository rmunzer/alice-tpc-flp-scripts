#include <chrono>
#include <TMath.h>
#include <fmt/format.h>
#include "rapidjson/document.h"
#include "rapidjson/filereadstream.h"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/error/error.h"
#include "rapidjson/error/en.h"
#include "CCDB/CcdbApi.h"
#include "TSystem.h"
#include "TStyle.h"
#include "CCDB/BasicCCDBManager.h"
#include "DataFormatsCalibration/MeanVertexObject.h"
#include "TGraph.h"
#include "TCanvas.h"
#include "TImage.h"
#include "TH1.h"
#include "TLine.h"
#include <curl/curl.h>
#include <error.h>
#include <fstream>
#include <sstream>
#include <string>

o2::ccdb::CcdbApi mCcdbApi;

using namespace o2::dataformats;
using namespace o2::math_utils;
using namespace std::chrono;
using namespace rapidjson;

// if startTimeOrRun < 1000000 then a run number is assumed, if only the first value us given, then it is a single run
// if both, startTimeOrRun < 0 and endTimeOrRun are -1, then interpret startTimeOrRun number of minutes before now
std::vector<std::string> split(std::string s, std::string delimiter) {
    size_t pos_start = 0, pos_end, delim_len = delimiter.length();
    std::string token;
    std::vector<std::string> res;

    while ((pos_end = s.find(delimiter, pos_start)) != std::string::npos) {
        token = s.substr (pos_start, pos_end - pos_start);
        pos_start = pos_end + delim_len;
        res.push_back (token);
    }

    res.push_back (s.substr (pos_start));
    return res;
}

void Sort_DCS(string fname="default",uint number_of_parameters=6, string verbosity="debug")
{
	fair::Logger::SetConsoleSeverity(verbosity);
	LOGF(info,"Create lumi files from input folder: ");
	ifstream file(fname);
	ofstream MyFile("output.txt");
	int counter=0;
    string line;
	vector<string> parameters;
	vector<bool> parameter_updated;
	vector<float> value;
	int last_time=0;
	bool write_header=true;
	int restart_time=0;
	int max_lines=1000000;
	int next_writeout=max_lines/10;
	int lines_written=0;
	

    if (file.is_open()) {
        while (getline(file, line)) {
            //cout << line << endl;
			vector<string> split_line=split(line,",");
			if(split_line.size()<3) continue;
			counter++;
			string param_tmp=split_line[1];
			int time_tmp=stoi(split_line[0]);
			float value_tmp = stof(split_line[2].substr (0, 7));
			uint j=0;
			for(j=0;j<parameters.size();j++){
				if(param_tmp==parameters[j]) break;
			}
			if(j==parameters.size()){
					parameters.push_back(param_tmp);
					value.push_back(value_tmp);
					parameter_updated.push_back(true);
					if(param_tmp=="tpc_dcs:Alice_Lumi.ZDC_Lumi") restart_time=time_tmp;
			}
			else{
					if(param_tmp=="tpc_dcs:Alice_Lumi.ZDC_Lumi"&&value_tmp<1) restart_time=time_tmp;
					value[j]=value_tmp;
					parameter_updated[j]=true;
			}
			
			bool print_out=true;
			for(j=0;j<parameter_updated.size();j++) if(!parameter_updated[j]) print_out=false;
			if((print_out||time_tmp>last_time)&&value[3]>0&&parameter_updated.size()==number_of_parameters){
				last_time=time_tmp;
				if(write_header){
					MyFile<<" Time,Time_in_Fill,";
					for(j=0;j<parameters.size()-1;j++) MyFile<<parameters[j]<<","; 
					MyFile<<parameters[parameters.size()-1]<<",";
					MyFile<<"D(RR),";	
					MyFile<<"D(GR),";
					MyFile<<"D(PS)"<<endl;		
					write_header=false;
				}	
				
				float D_GR=value[1]-8.4;
				float D_RR=value[0]-77.5;
				float D_PS=value[2]-366;
				
				
				if(value[5]>103.0&&fabs(D_RR)<2){
					MyFile<<time_tmp<<","<<time_tmp-restart_time<<","; for(j=0;j<parameters.size()-1;j++) 	
					MyFile<<value[j]<<","; 
				    MyFile<<value[parameters.size()-1]<<",";
					MyFile<<D_RR<<","; 
					MyFile<<D_GR<<","; 
					MyFile<<D_PS<<"," <<endl; 
					for(uint k=0;k<parameter_updated.size();k++) parameter_updated[k]=false;
					lines_written++;
				}
			}	
			if(counter==next_writeout){
				cout<<"Processed line: "<<counter<<endl;
				next_writeout+=max_lines/10;
			}	
			if(counter>max_lines) break;
        }
		cout<<"Line written: "<<lines_written<<endl;

        // Close the file stream once all lines have been
        // read.
        file.close();
		MyFile.close();
    }
    else {
        // Print an error message to the standard error
        // stream if the file cannot be opened.
        cerr << "Unable to open file!" << endl;
    }
}

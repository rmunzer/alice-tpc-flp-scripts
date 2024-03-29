// Copyright 2019-2020 CERN and copyright holders of ALICE O2.
// See https://alice-o2.web.cern.ch/copyright for details of the copyright holders.
// All rights not expressly granted are reserved.
//
// This software is distributed under the terms of the GNU General Public
// License v3 (GPL Version 3), copied verbatim in the file "COPYING".
//
// In applying this license CERN does not waive the privileges and immunities
// granted to it by virtue of its status as an Intergovernmental Organization
// or submit itself to any jurisdiction.

//#if !defined(__CLING__) || defined(__ROOTCLING__)
#include <CCDB/BasicCCDBManager.h>
#include <DataFormatsCTP/Configuration.h>
#include <DataFormatsParameters/GRPLHCIFData.h>
//#endif
#include <TMath.h>
using namespace o2::ctp;

void Print_Output(string source,int run,double_t Trun,double_t integral,double_t nbc){
		double_t frev=11245;
		double_t sigmaratio=28;
		double_t rate = 0.;
		if(Trun>0) rate=integral / Trun;
		double_t rat = 0.;
		if(Trun>0 && nbc>0 && frev >0 ) rat=integral / Trun / nbc / frev;
		double_t mu = -TMath::Log(1 - rat);
		double_t pp = 0.;
		if(mu>0) pp=1 - mu / (TMath::Exp(mu) - 1);
		double_t ratepp = mu * nbc * frev;
		double_t integralpp = ratepp * Trun;
		std::cout << run << "-"<<source<<":";
		std::cout << "Rate:" << rate / sigmaratio << " Integral:" << integral << " mu:" << mu << " Pileup prob:" << pp;
		std::cout << " Integralpp:" << integralpp << " Ratepp:" << ratepp / sigmaratio << std::endl;
}
void Print_Output(string source,int run,std::vector<CTPScalerRecordO2> recs,int inp,double_t nbc){
	
	double_t first=recs[0].scalersInps[inp - 1];
	double_t last=recs[recs.size() - 1].scalersInps[inp - 1];
	double_t integral=last-first;
	if(first>last) integral=first-last+pow(2,32);
	Print_Output(source,run,recs[recs.size() - 1].epochTime-recs[0].epochTime,integral,nbc);
	
}
void GetScalersForRun(string runNumberList, int fillN = 0, bool PbPb_run=true)
{
	std::size_t posOpen = runNumberList.find("[");
    std::size_t posClose = runNumberList.find("]");
	runNumberList.erase(posClose,1);
	runNumberList.erase(posOpen,1);
	
	std::string delimiter = ",";
	string token;
	size_t pos = 0;
	vector<int> runNumbers;
	while ((pos = runNumberList.find(delimiter)) != std::string::npos) {
		token = runNumberList.substr(0, pos);
		std::cout << token << std::endl;
		runNumberList.erase(0, pos + delimiter.length());
		runNumbers.push_back(stoi(token));
	}
	runNumbers.push_back(stoi(runNumberList));
	std::cout << "Number of run: "<<runNumbers.size()<<endl;
	
	std::string mCCDBPathCTPScalers = "CTP/Calib/Scalers";
	std::string mCCDBPathCTPConfig = "CTP/Config/Config";
	auto& ccdbMgr = o2::ccdb::BasicCCDBManager::instance();
	ccdbMgr.setURL("http://o2-ccdb.internal");
	
	std::cout << "CCDB Manager created:" << std::endl;

	uint64_t timeStamp=0;
	vector<uint64_t> timeStamp_list;
	for(uint j=0;j<runNumbers.size();j++){
			auto soreor = ccdbMgr.getRunDuration(runNumbers[j],false);	
			cout<<"Run: "<<runNumbers[j]<<" "<<soreor.second<<" "<<soreor.first<<" "<<soreor.second - soreor.first<<endl;
			uint64_t timeStamp_temp = 0;
			if(soreor.second>0 && soreor.first>0)timeStamp_temp=(soreor.second - soreor.first) / 2 + soreor.first;
			timeStamp_list.push_back(timeStamp_temp );
			if(timeStamp_temp > 0 && timeStamp==0 ) timeStamp=timeStamp_temp;
	}
	std::cout << "Timestamp:" << timeStamp << std::endl;
	if(timeStamp==0){
		for(uint j=0;j<runNumbers.size();j++){
			std::cout << runNumbers[j] << "-ZNC:";
			std::cout << "Rate:" << 0 << " Integral:" << 0 << " mu:" << 0 << " Pileup prob:" << 0;
			std::cout << " Integralpp:" << 0 << " Ratepp:" << 0 << std::endl;
		}
		return;
	}
	//
	std::string sfill = std::to_string(fillN);
	std::map<string, string> metadata;
	metadata["fillNumber"] = sfill;
	ccdbMgr.setURL("http://o2-ccdb.internal");
	auto lhcifdata = ccdbMgr.getSpecific<o2::parameters::GRPLHCIFData>("GLO/Config/GRPLHCIF", timeStamp, metadata);
	auto bfilling = lhcifdata->getBunchFilling();
	std::vector<int> bcs = bfilling.getFilledBCs();
	std::cout << "Number of interacting bc:" << bcs.size() << std::endl;
	std::cout << " Get all run for that fill " << endl;
	for(uint j=0;j<runNumbers.size();j++){

		
		
		
		
		
		std::string srun = std::to_string(runNumbers[j]);
		metadata.clear(); // can be empty
		metadata["runNumber"] = srun;
		ccdbMgr.setFatalWhenNull(false);
		auto ctpscalers = ccdbMgr.getSpecific<CTPRunScalers>(mCCDBPathCTPScalers, timeStamp_list[j], metadata);
		if (ctpscalers == nullptr) {
			LOG(info) << "CTPRunScalers not in database, timestamp:" <<  timeStamp_list[j];
			Print_Output("ZNC",runNumbers[j],0,0,0);
			Print_Output("FT0",runNumbers[j],0,0,0);
			continue;
		}		
		
		auto ctpcfg = ccdbMgr.getSpecific<CTPConfiguration>(mCCDBPathCTPConfig,  timeStamp_list[j], metadata);
		if (ctpcfg == nullptr) {
			LOG(info) << "CTPRunConfig not in database, timestamp:" <<  timeStamp_list[j];
			Print_Output("ZNC",runNumbers[j],0,0,0);
			Print_Output("FT0",runNumbers[j],0,0,0);
			continue;
		}
		std::cout << "all good" << std::endl;
		if(runNumbers[j]>544448){
			ctpscalers->convertRawToO2();
			std::vector<CTPScalerRecordO2> recs = ctpscalers->getScalerRecordO2();
			if (recs[0].scalersInps.size() == 48) {
				int inp = 26;
				
				
				Print_Output("ZNC",runNumbers[j],recs,26,bcs.size());
				inp = 2;
				Print_Output("ZNC",runNumbers[j],recs,2,bcs.size());
			}
		}
		else{
			std::vector<CTPClass> ctpcls = ctpcfg->getCTPClasses();
			std::vector<int> clslist = ctpcfg->getTriggerClassList();
			//std::vector<uint32_t> clslist = ctpscalers->getClassIndexes();
			std::map<int, int> clsIndexToScaler;
			std::cout << "Classes:";
			int i = 0;
			for (auto const& cls : clslist) {
				std::cout << cls << " ";
				clsIndexToScaler[cls] = i;
				i++;
			}
			std::cout << std::endl;
			int tsc = 255;
			int tce = 255;
			int vch = 255;
			int iznc = 255;
			for (auto const& cls : ctpcls) {
				std::cout << cls.name <<endl;
				if (cls.name.find("CMTVXTSC-B-NOPF-CRU") != std::string::npos) {
					tsc = cls.getIndex();
					std::cout << cls.name << ":" << tsc << std::endl;
				}
				if (cls.name.find("CMTVXTCE-B-NOPF-CRU") != std::string::npos) {
					tce = cls.getIndex();
					std::cout << cls.name << ":" << tce << std::endl;
				}
				if (cls.name.find("CMTVXVCH-B-NOPF-CRU") != std::string::npos) {
					vch = cls.getIndex();
					std::cout << cls.name << ":" << vch << std::endl;
				}
				// if (cls.name.find("C1ZNC-B-NOPF-CRU") != std::string::npos) {
				if (cls.name.find("C1ZNC-B-NOPF") != std::string::npos) {
					iznc = cls.getIndex();
					std::cout << cls.name << ":" << iznc << std::endl;
				}
			}
			if( tsc==255 && tce==255 && vch==255){
					continue;
					Print_Output("ZNC",runNumbers[j],0,0,0);
					Print_Output("FT0",runNumbers[j],0,0,0);
			}
			ctpscalers->convertRawToO2();
			// inp = 2;
			std::vector<CTPScalerRecordO2> recs = ctpscalers->getScalerRecordO2();
			for(int inp=1;inp<20;inp++){
				Print_Output("FT0"+std::to_string(inp),runNumbers[j],recs[recs.size() - 1].epochTime-recs[0].epochTime,recs[recs.size() - 1].scalersInps[inp - 1] - recs[0].scalersInps[inp - 1],bcs.size());
			}
			if (tsc != 255 ) {
				std::cout << "TSC:";
				ctpscalers->printClassBRateAndIntegral(clsIndexToScaler[tsc] + 1);
			}
			if (tce != 255) {
				std::cout << "TCE:";
				ctpscalers->printClassBRateAndIntegral(clsIndexToScaler[tce] + 1);
			}
			// std::cout << "TCE input:" << ctpscalers->printInputRateAndIntegral(5) << std::endl;;
			if (vch != 255) {
				std::cout << "VCH:";
				ctpscalers->printClassBRateAndIntegral(clsIndexToScaler[vch] + 1);
			}
			if (iznc != 255) {
				std::cout << "ZNC class:";
				// uint64_t integral = recs[recs.size() - 1].scalers[iznc].l1After - recs[0].scalers[iznc].l1After;
				auto zncrate = ctpscalers->getRateGivenT(0, iznc, 6);
				std::cout << "ZNC class rate:" << zncrate.first / 28. << std::endl;
			} else {
			std::cout << "ZNC class not available" << std::endl;
			}
		}
	}
}



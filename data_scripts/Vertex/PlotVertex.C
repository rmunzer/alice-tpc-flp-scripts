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

o2::ccdb::CcdbApi mCcdbApi;

using namespace o2::dataformats;
using namespace o2::math_utils;
using namespace std::chrono;
using namespace rapidjson;

// if startTimeOrRun < 1000000 then a run number is assumed, if only the first value us given, then it is a single run
// if both, startTimeOrRun < 0 and endTimeOrRun are -1, then interpret startTimeOrRun number of minutes before now

size_t getAnswerFunction(void* ptr, size_t size, size_t nmemb, std::string* data) {
	data->append((char*)ptr, size * nmemb);	
	return size * nmemb;
}


void PlotVertex(int fillN = 9570,int fillNstop = 0,string output_folder="./",string output_folder_txt="./",bool plot_vertex=true, string verbosity="error")
{
  fair::Logger::SetConsoleSeverity(verbosity);
  mCcdbApi.init("http://o2-ccdb.internal");
  long startTimeOrRun = 0;
  long endTimeOrRun = 0;
  char* token=getenv("BK_TOKEN");
  cout<<"Token: "<<token<<endl;
  cout<<"FillNumber: "<<fillN<<endl;
  cout<<"Output_Folder: "<<output_folder<<endl;
  string output_file=output_folder_txt+"/"+std::to_string(fillN)+"_lumireg_ALICE.txt";
  string output_file_root=output_folder+""+std::to_string(fillN)+"_lumi_ALICE.root";
  string output_file_png=output_folder+""+std::to_string(fillN)+"_lumi_ALICE.png";
  string output_file_mean_png=output_folder+""+std::to_string(fillN)+"_lumi_ALICE_mean.png";
  string output_file_sigma_z_png=output_folder+""+std::to_string(fillN)+"_sigma_z_ALICE.png";
  
  
  cout<<"Output File:"<<output_file<<endl;
  if(fillN<100){
	  int time_stamp_2024=1704067200; 
	  startTimeOrRun=(time_stamp_2024+(fillN-1)*7*24*3600);
	  endTimeOrRun=(time_stamp_2024+(fillN)*7*24*3600);
	  cout<<"Time period: "<<startTimeOrRun<<"-"<<endTimeOrRun<<endl;
	  startTimeOrRun*=1000;
	  endTimeOrRun*=1000;
	  cout<<"Time period: "<<startTimeOrRun<<"-"<<endTimeOrRun<<endl;
  }
  else if(fillN>50000){
	  startTimeOrRun=fillN ;
	  endTimeOrRun=fillNstop;
	  startTimeOrRun*=1000;
	  endTimeOrRun*=1000;
  }
  else{
		  
	  CURL *curl= curl_easy_init();
	  CURLcode res;
	  std::string readBuffer;
	  string url="https://ali-bookkeeping.cern.ch/api/lhcFills/";
	  string token_str(token);
	  url+=std::to_string(fillN);
	  url+="?token=";
	  url+=token_str;
	  cout<<"url: "<<url<<endl;
	  if(curl) {
		struct curl_slist *list = NULL;
		list = curl_slist_append(list, "Content-Type: application/json");
		curl_easy_setopt(curl, CURLOPT_HTTPHEADER, list);
		curl_easy_setopt(curl, CURLOPT_URL, url.data());
		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, false);
		curl_easy_setopt(curl, CURLOPT_PROXY, "10.161.69.44:8080");
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, getAnswerFunction);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, &readBuffer);
		res = curl_easy_perform(curl);
		curl_easy_cleanup(curl);


		rapidjson::Document docfill;
		docfill.Parse(readBuffer.data());
		if (!docfill.IsObject()) {
			throw std::runtime_error(fmt::format("Failed to parse object"));
		  }	
		if (!docfill.HasMember("data")) {
			throw std::runtime_error(fmt::format("No object data found"));
		}
		cout<<docfill["data"].MemberCount()<<endl;
		if (!docfill["data"]["stableBeamsStart"].IsNumber()) {
			throw std::runtime_error(fmt::format("No object stableBeamsStart found"));
		}
		startTimeOrRun=docfill["data"]["stableBeamsStart"].GetDouble();
		endTimeOrRun=docfill["data"]["stableBeamsEnd"].GetDouble();

	  }
	  else{
		std::cout<<"Curl not avail"<<endl;
	  }
  }
  
  std::string_view path("GLO/Calib/MeanVertex");
  int runNumber_set=-1;
  auto& ccdbMan = o2::ccdb::BasicCCDBManager::instance();
  ccdbMan.setURL("http://o2-ccdb.internal");
  // assume run numbers
  if (startTimeOrRun > -1 && startTimeOrRun < 1000000 && endTimeOrRun < 1000000) {
    runNumber_set=startTimeOrRun;
    if (endTimeOrRun == -1) {
      endTimeOrRun = startTimeOrRun;
      
    }

    auto runRangeStart = ccdbMan.getRunDuration(startTimeOrRun);
    auto runRangeEnd = ccdbMan.getRunDuration(endTimeOrRun);

    startTimeOrRun = runRangeStart.first;
    endTimeOrRun = runRangeEnd.second;
  }

  if (startTimeOrRun < 0 && endTimeOrRun == -1) {
    startTimeOrRun = std::chrono::duration_cast<std::chrono::milliseconds>((std::chrono::system_clock::now() + std::chrono::minutes(startTimeOrRun)).time_since_epoch()).count();
    endTimeOrRun = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
  }

  // try up to nTrial times in case we get a server error
  std::string json;
  bool gotList = false;
  const int nTrial = 10;
  for (int i = 0; i < nTrial; ++i) {
    try {
      json = mCcdbApi.list(path.data(), false, "application/json");
      gotList = true;
    } catch (...) {
      gotList = false;
    }
    if (gotList && (json.substr(0, 20).find("doctype html") == std::string::npos)) {
      break;
    }
    fmt::print("Failed to get list for {} trial {} / {}, error: {} ...\n", path, i, nTrial, json.substr(0, 100));
    gSystem->Sleep(10);
  }

  rapidjson::Document doc;
  doc.Parse(json.data());

  if (!doc.IsObject() || !doc.HasMember("objects") || !doc["objects"].IsArray()) {
    throw std::runtime_error(fmt::format("could not parse object list for {}", path));
  }

  auto entries = doc["objects"].GetArray();
  LOGP(info, "Found {} entries for object {}", entries.Size(), path);


  // remove elements outside the range, or not spanning the range
  entries.Erase(std::remove_if(entries.begin(), entries.end(), [startTimeOrRun, endTimeOrRun](const auto& entry) {
                  const auto startValidity = entry["validFrom"].GetInt64();
                  const auto endValidity = entry["validUntil"].GetInt64();
                  return ((startValidity < startTimeOrRun) || (startValidity >= endTimeOrRun)) && !((startValidity <= startTimeOrRun) && (endValidity >= endTimeOrRun));
                }),
                entries.end());

  // sort by time
  std::sort(entries.begin(), entries.end(), [](const auto& a, const auto& b) { return a["validFrom"].GetInt64() < b["validFrom"].GetInt64(); });

  LOGP(info, "Found {} entries for object {} after filtering between {} - {}", entries.Size(), path, startTimeOrRun, endTimeOrRun);

  auto xpos = new TGraph;
  auto ypos = new TGraph;
  auto zpos = new TGraph;
  auto xsigma = new TGraph;
  auto ysigma = new TGraph;
  auto zsigma = new TGraph;
  string TH1D_name="Z Position - Fill "+std::to_string(fillN);
  if(fillN<100){
		  TH1D_name="Z Position - Week "+std::to_string(fillN);
  }
  auto zpos_mean= new TH1D(TH1D_name.c_str(),TH1D_name.c_str(),100,-10.,-10);
  
  ofstream out;
  out.open(output_file.data(),ios::out);
  if (out.fail()) cerr << "open failure as expected: " << strerror(errno) << '\n';
  
  for (const auto& entry : entries) {
    const auto startValidity = entry["validFrom"].GetInt64();
    if (startValidity < 1420066800000) {
      continue;
    }
    const auto endValidity = entry["validUntil"].GetInt64();
    int runNumber = 0;
    if (entry.FindMember("runNumber") != entry.MemberEnd()) {
      runNumber = std::atoi(entry["runNumber"].GetString());
    }
    std::map<std::string, std::string> mm, mm2;
    auto obj = mCcdbApi.retrieveFromTFileAny<o2::dataformats::MeanVertexObject>(path.data(), mm, startValidity, &mm2);
    if (!obj) {
      continue;
    }
    if( ( runNumber_set < 0 ) || ( runNumber_set == runNumber ) ){

      double pos_x=obj->getX()*-10.;  // Convert to mm
      double pos_y=obj->getY()*10.;  // Convert to mm
      double pos_z=obj->getZ()*-10.;  // Convert to mm. Invert due agree with Machine conventions 
	  double pos_x_sigma=obj->getSigmaX()*10.;
      double pos_y_sigma=obj->getSigmaY()*10.;
      double pos_z_sigma=obj->getSigmaZ()*10.; 
	  double pos_xsu=0.;
      double pos_ysu=0.;
      double pos_zsu=0.;
	  double pos_xsu_sigma=0.;
      double pos_ysu_sigma=0.;
      double pos_zsu_sigma=0.;
      double pos_ax=0.;
      double pos_ay=0.;
	  double pos_ax_sigma=0.;
      double pos_ay_sigma=0.;
      xpos->AddPoint(double(startValidity / 1000.), pos_x);
      ypos->AddPoint(double(startValidity / 1000.), pos_y);
      zpos->AddPoint(double(startValidity / 1000.), pos_z);
      xsigma->AddPoint(double(startValidity / 1000.), pos_x_sigma);
      ysigma->AddPoint(double(startValidity / 1000.), pos_y_sigma);
      zsigma->AddPoint(double(startValidity / 1000.), pos_z_sigma);
	  zpos_mean->Fill(pos_z);

	  if( fillN < 100){	
		fmt::print("week: {} run: {}, start: {}, x: {} cm,y: {} cm,z: {} cm, sx: {} cm,sy: {} cm,sz: {} cm\n", fillN, runNumber, startValidity / 1000., pos_x, pos_y , pos_z,pos_x_sigma,pos_y_sigma,pos_z_sigma);
	  }
	  else{
		fmt::print("fill: {} run: {}, start: {}, x: {} cm,y: {} cm,z: {} cm, sx: {} cm,sy: {} cm,sz: {} cm\n", fillN, runNumber, startValidity / 1000., pos_x, pos_y , pos_z,pos_x_sigma,pos_y_sigma,pos_z_sigma);
	  }
	  
	  
      out <<fixed<<startValidity / 1000. <<" "<< 1 <<" "<< pos_x <<" "<<pos_x_sigma<<" "<< pos_y <<" "<< pos_y_sigma <<" "<< pos_z <<" "<< pos_z_sigma <<" "<< pos_xsu <<" "<< pos_ysu <<" "<< pos_zsu <<" "<< pos_xsu_sigma <<" "<< pos_ysu_sigma <<" "<< pos_zsu_sigma <<" "<< pos_ax <<" "<< pos_ay <<" "<< pos_ax_sigma <<" "<< pos_ay_sigma <<endl;
    }
    delete obj;
  }
  out.close();
  if(plot_vertex){
	  gStyle->SetTimeOffset(0);
	  auto meanvert_mean = new TCanvas("Vertex Mean","Vertex",1800,600);
	  zpos_mean->Draw();
	  TImage *img_mean = TImage::Create();
	  img_mean ->FromPad(meanvert_mean);
	  img_mean ->WriteImage(output_file_mean_png.c_str());
	  
	if(1){ // Plot z vertex trend
	  auto meanvert = new TCanvas("Vertex","Vertex",1800,600);
	  meanvert->Divide(1,1,0,0);
	  meanvert->cd(1);
	  string title="Fill "+std::to_string(fillN);
	  if(fillN<100){
		  title="Week "+std::to_string(fillN);
	  }
	  zpos->SetTitle(title.c_str());
	  zpos->SetMarkerStyle(20);
	  zpos->SetMarkerSize(1);
	  zpos->Draw("ap");
	  float xmin=zpos->GetXaxis()->GetXmin();
	  float xmax=zpos->GetXaxis()->GetXmax();
	  TLine *l1=new TLine(xmin,-5,xmax,-5);
	  l1->SetLineColor(kYellow);
	  l1->Draw("");
	  TLine *l2=new TLine(xmin,5,xmax,5);
	  l2->SetLineColor(kYellow);
	  l2->Draw("");
	  TLine *l3=new TLine(xmin,-10,xmax,-10);
	  l3->SetLineColor(kRed);
	  l3->Draw("");
	  TLine *l4=new TLine(xmin,10,xmax,10);
	  l4->SetLineColor(kRed);
	  l4->Draw("");
	  TLine *l5=new TLine(xmin,0,xmax,0);
	  l5->SetLineColor(kGreen);
	  l5->Draw("");
	  meanvert->Modified();
	  meanvert->Update();
	  auto azx = ((TH1*)zpos->GetHistogram())->GetXaxis();
	  auto azy = ((TH1*)zpos->GetHistogram())->GetYaxis();
	  azx->SetTimeDisplay(1);
	  azx->SetTimeFormat("#splitline{%d.%m.%y}{%H:%M:%S}");
	  azx->SetLabelOffset(0.025);
	  azx->SetLabelSize(0.05);
	  azy->SetRangeUser(-12,12.);
	  azy->SetTitle("z [mm]");
	  TImage *img = TImage::Create();
	  img->FromPad(meanvert);
	  img->WriteImage(output_file_png.c_str());
	  meanvert->SaveAs(output_file_root.c_str());
	}
	if(1){ // Plot z-sigma trend
	  auto vertsigmax = new TCanvas("Vertex","Vertex",1800,600);
	  vertsigmax->Divide(1,1,0,0);
	  vertsigmax->cd(1);
	  string titles="Sigma z - Fill "+std::to_string(fillN);
	  if(fillN<100){
		  titles="Sigma z - Week "+std::to_string(fillN);
	  }
	  zsigma->SetTitle(titles.c_str());
	  zsigma->SetMarkerStyle(20);
	  zsigma->SetMarkerSize(1);
	  zsigma->Draw("ap");
	  auto xmin=zsigma->GetXaxis()->GetXmin();
	  auto xmax=zsigma->GetXaxis()->GetXmax();
	  TLine *l1s=new TLine(xmin,70,xmax,70);
	  l1s->SetLineColor(kRed);
	  l1s->Draw("");
	  
	  vertsigmax->Modified();
	  vertsigmax->Update();
	  auto azxs = ((TH1*)zsigma->GetHistogram())->GetXaxis();
	  auto azys = ((TH1*)zsigma->GetHistogram())->GetYaxis();
	  azxs->SetTimeDisplay(1);
	  azxs->SetTimeFormat("#splitline{%d.%m.%y}{%H:%M:%S}");
	  azxs->SetLabelOffset(0.025);
	  azxs->SetLabelSize(0.05);
	  azys->SetRangeUser(0,120.);
	  azys->SetTitle("z [mm]");
		TImage *imgs = TImage::Create();
		imgs->FromPad(vertsigmax);

	   imgs->WriteImage(output_file_sigma_z_png.c_str());
	}

  }
}

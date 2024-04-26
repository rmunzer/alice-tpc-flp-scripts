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
#include "TH1.h"
#include <curl/curl.h>
#include <error.h>
#include <fstream>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>

o2::ccdb::CcdbApi mCcdbApi;

using namespace o2::dataformats;
using namespace o2::math_utils;
using namespace rapidjson;

// if startTimeOrRun < 1000000 then a run number is assumed, if only the first value us given, then it is a single run
// if both, startTimeOrRun < 0 and endTimeOrRun are -1, then interpret startTimeOrRun number of minutes before now
void PlotVertex(long startTimeOrRun = -24 * 60, long endTimeOrRun = -1)
{
  mCcdbApi.init("http://o2-ccdb.internal");
  
  
  
  CURL *curl= curl_easy_init();
  CURLcode res;
  std::string readBuffer;
  string url="https://ali-bookkeeping.cern.ch/api/lhcFills/9436?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Mzg3ODQ0LCJ1c2VybmFtZSI6ImFsaWNlcmMiLCJuYW1lIjoiQUxJQ0UgUnVuIENvb3JkaW5hdGlvbiIsImFjY2VzcyI6ImFkbWluIiwiaWF0IjoxNzEyODI4NTMwLCJleHAiOjE3NDQzODYxMzAsImlzcyI6Im8yLXVpIn0.7_C4jkE99aiXlDIMI65jyXkgjJIPJSYmvotRHeNQuxA";

  if(curl) {
	struct curl_slist *list = NULL;
	list = curl_slist_append(list, "Content-Type: application/json");
	curl_easy_setopt(curl, CURLOPT_HTTPHEADER, list);
    curl_easy_setopt(curl, CURLOPT_URL, url.data());
	curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, false);
	curl_easy_setopt(curl, CURLOPT_PROXY, "10.161.69.44:8080");
	
    curl_easy_setopt(curl, CURLOPT_READDATA, &readBuffer);
    res = curl_easy_perform(curl);
    curl_easy_cleanup(curl);
	std::ofstream out("output.txt");
    out << readBuffer;
    out.close();

    std::cout << readBuffer << " "<< res<<"\n"<<std::endl;
    std::cout << std::endl;
	std::stringstream ss;
	ss << readBuffer;
    boost::property_tree::ptree jsontree;
    boost::property_tree::read_json(ss, jsontree);

    string v0 = jsontree.get<string>("data");


  }
  else{
	std::cout<<"Curl not avail"<<endl;
  }
  

  
  return;
  
  
  
  
  
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
  
  cout<<json<<endl;
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
	  auto x = obj->getX();
	  auto y = obj->getY();
	  auto z = obj->getZ();
      xpos->AddPoint(double(startValidity / 1000.), double(obj->getX()));
      ypos->AddPoint(double(startValidity / 1000.), double(obj->getY()));
      zpos->AddPoint(double(startValidity / 1000.), double(obj->getZ()));
      fmt::print("run: {}, start: {}, vDrift: {} cm\n", runNumber, startValidity / 1000., obj->getZ());
    }
    delete obj;
  }
  gStyle->SetTimeOffset(0);
  auto meanvert = new TCanvas("Vertex","Vertex",1800,600);
  meanvert->Divide(3,1,0,0);
  meanvert->cd(1);
  zpos->SetMarkerStyle(20);
  zpos->SetMarkerSize(1);
  zpos->Draw("alp");
  meanvert->Modified();
  meanvert->Update();
  auto azx = ((TH1*)zpos->GetHistogram())->GetXaxis();
  azx->SetTimeDisplay(1);
  azx->SetTimeFormat("#splitline{%d.%m.%y}{%H:%M:%S}");
  azx->SetLabelOffset(0.025);
  azx->SetLabelSize(0.05);
  azx->SetTitle("");
  meanvert->cd(2);
  xpos->SetMarkerStyle(20);
  xpos->SetMarkerSize(1);
  xpos->Draw("alp");
  meanvert->Modified();
  meanvert->Update();
  auto axx = ((TH1*)xpos->GetHistogram())->GetXaxis();
  axx->SetTimeDisplay(1);
  axx->SetTimeFormat("#splitline{%d.%m.%y}{%H:%M:%S}");
  axx->SetLabelOffset(0.025);
  axx->SetLabelSize(0.05);
  axx->SetTitle("");
}

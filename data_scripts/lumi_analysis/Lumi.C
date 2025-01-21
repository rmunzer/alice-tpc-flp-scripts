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

void Lumi(string fname="default", string verbosity="debug")
{
 fair::Logger::SetConsoleSeverity(verbosity);
 LOGF(info,"Create lumi files from input folder: ");
}

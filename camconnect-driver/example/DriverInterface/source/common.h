#pragma once

#include <SDKDDKVer.h>

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <dshow.h>
#include <dvdmedia.h>

#include <string>

#define EXPORT extern "C" __declspec(dllexport)
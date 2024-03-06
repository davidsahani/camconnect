// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.custom.camera;

import android.graphics.Rect;
import android.os.Build;
import android.util.Size;
import android.app.Activity;
import android.content.Context;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.params.StreamConfigurationMap;
import androidx.annotation.NonNull;
import android.graphics.SurfaceTexture;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

/** Provides various utilities for camera. */
public final class CameraUtils {

  private CameraUtils() {}

  public static List<Map<String, Integer>> getSupportedResolutions(CameraCharacteristics cameraCharacteristics) {
    StreamConfigurationMap streamMap = (StreamConfigurationMap)cameraCharacteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
    int supportLevel = (Integer)cameraCharacteristics.get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL);
    android.util.Size[] nativeSizes = streamMap.getOutputSizes(SurfaceTexture.class);

   List<Map<String, Integer>> resolutionsMap = new ArrayList<>();

    if (Build.VERSION.SDK_INT < 22 && supportLevel == 2) {
      Rect activeArraySize = (Rect)cameraCharacteristics.get(CameraCharacteristics.SENSOR_INFO_ACTIVE_ARRAY_SIZE);

      int width = activeArraySize.width();
      int height = activeArraySize.height();

      for (android.util.Size size : nativeSizes)
      {
        if (width * size.getHeight() == height * size.getWidth())
        {
          long minFrameDurationNs = streamMap.getOutputMinFrameDuration(SurfaceTexture.class, size);
          int maxFrameRate = (int)Math.round(1.0E9 / (double)minFrameDurationNs);

          resolutionsMap.add(new HashMap<String, Integer>() {{
            put("width", size.getWidth());
            put("height", size.getHeight());
            put("maxFps", maxFrameRate);
          }});
        }
      }

    } else {
      for (android.util.Size size : nativeSizes)
      {
        long minFrameDurationNs = streamMap.getOutputMinFrameDuration(SurfaceTexture.class, size);
        int maxFrameRate = (int)Math.round(1.0E9 / (double)minFrameDurationNs);

        resolutionsMap.add(new HashMap<String, Integer>() {{
          put("width", size.getWidth());
          put("height", size.getHeight());
          put("maxFps", maxFrameRate);
        }});
      }
    }
    return  resolutionsMap;
  }
}

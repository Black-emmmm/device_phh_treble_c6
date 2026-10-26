/*
 * Copyright (C) 2018 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.android.settings.security;

import android.content.Context;
import android.text.TextUtils;

import androidx.preference.Preference;

import com.android.settings.core.BasePreferenceController;
import com.android.settings.core.SubSettingLauncher;
import com.android.settings.overlay.FeatureFactory;
import com.android.settings.safetycenter.SafetyCenterManagerWrapper;
import com.google.android.settings.security.SecurityHubDashboard;

public class TopLevelSecurityEntryPreferenceController extends BasePreferenceController {

    private final SecuritySettingsFeatureProvider mSecuritySettingsFeatureProvider;

    public TopLevelSecurityEntryPreferenceController(Context context, String preferenceKey) {
        super(context, preferenceKey);
        mSecuritySettingsFeatureProvider = FeatureFactory.getFactory(mContext)
                .getSecuritySettingsFeatureProvider();
    }

    @Override
    public int getAvailabilityStatus() {
        if (!SafetyCenterManagerWrapper.get().isEnabled(mContext)) {
            return AVAILABLE;
        }
        return CONDITIONALLY_UNAVAILABLE;
    }

    @Override
    public boolean handlePreferenceTreeClick(Preference preference) {
        if (!TextUtils.equals(preference.getKey(), getPreferenceKey())) {
            return super.handlePreferenceTreeClick(preference);
        }

        // CB-C6: 原版这里把目的地硬编码成 Google 的 SecurityHubDashboard，
        // 该 Fragment 依赖 SafetyCenter / Phenotype 数据源，本机（无 GMS、无 SafetyCenter 模块）
        // 拿不到回调，会永远停在"正在加载..."。改为按 top_level_settings.xml 里声明的
        // fragment（com.android.settings.security.SecuritySettings）正常跳转。
        return super.handlePreferenceTreeClick(preference);
    }
}

/*
 * Copyright (C) 2021 The Android Open Source Project
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

package com.android.keyguard;

import android.view.View;

import com.android.systemui.util.ViewController;

import javax.inject.Inject;

/**
 * Controller for {@link CarrierText}.
 */
public class CarrierTextController extends ViewController<CarrierText> {
    private final CarrierTextManager mCarrierTextManager;
    private final KeyguardUpdateMonitor mKeyguardUpdateMonitor;
    private final CarrierTextManager.CarrierTextCallback mCarrierTextCallback =
            new CarrierTextManager.CarrierTextCallback() {
                @Override
                public void updateCarrierInfo(CarrierTextManager.CarrierTextCallbackInfo info) {
                    // CB-C6: 本机没有 modem/SIM，运营商文字恒为「没有服务」，锁屏左上角
                    // 一直挂着一行灰字，纯噪音。只在文案是「无服务」默认值（或为空）时隐藏，
                    // 插卡设备照常显示运营商名，不影响任何功能。
                    final String text = info.carrierText == null ? "" : info.carrierText.toString();
                    final String noService = mView.getContext().getString(
                            com.android.internal.R.string.lockscreen_carrier_default);
                    mView.setText(text);
                    mView.setVisibility((text.trim().isEmpty() || text.contains(noService))
                            ? View.GONE : View.VISIBLE);
                }

                @Override
                public void startedGoingToSleep() {
                    mView.setSelected(false);
                }

                @Override
                public void finishedWakingUp() {
                    mView.setSelected(true);
                }
            };

    @Inject
    public CarrierTextController(CarrierText view,
            CarrierTextManager.Builder carrierTextManagerBuilder,
            KeyguardUpdateMonitor keyguardUpdateMonitor) {
        super(view);

        mCarrierTextManager = carrierTextManagerBuilder
                .setShowAirplaneMode(mView.getShowAirplaneMode())
                .setShowMissingSim(mView.getShowMissingSim())
                .build();
        mKeyguardUpdateMonitor = keyguardUpdateMonitor;
    }

    @Override
    protected void onInit() {
        super.onInit();
        mView.setSelected(mKeyguardUpdateMonitor.isDeviceInteractive());
    }

    @Override
    protected void onViewAttached() {
        mCarrierTextManager.setListening(mCarrierTextCallback);
    }

    @Override
    protected void onViewDetached() {
        mCarrierTextManager.setListening(null);
    }
}

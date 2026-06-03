package com.biogenix.optimus.optimus_cgm_flutter

import android.app.Application
import com.eaglenos.blehealth.cgm.CgmDeviceManager

class OptimusApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        CgmDeviceManager.getInstance().init(this)
    }
}

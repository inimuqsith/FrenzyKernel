// ==============================================================================
// FrenzyServer WebUI Controller v3.0
// Universal KSU Bridge & Local HTTP REST API
// ==============================================================================

let callbackCounter = 0;
function getUniqueCallbackName(prefix) {
  return `${prefix}_callback_${Date.now()}_${callbackCounter++}`;
}

// Universal Root Command Runner (KSU Native + HTTP Fallback)
async function exec(command) {
  // 1. Check if running inside KernelSU Manager WebView
  if (typeof ksu !== "undefined" && ksu.exec) {
    return new Promise((resolve, reject) => {
      const callbackName = getUniqueCallbackName("exec");
      window[callbackName] = (errno, stdout, stderr) => {
        resolve({ errno, stdout, stderr });
        delete window[callbackName];
      };
      try {
        ksu.exec(command, JSON.stringify({}), callbackName);
      } catch (e) {
        delete window[callbackName];
        reject(e);
      }
    });
  }

  // 2. Fallback: Check if running via HTTP (port 8888)
  try {
    let apiCmd = "";
    if (command.includes("json")) apiCmd = "json";
    else if (command.includes("mode tier2")) apiCmd = "tier2";
    else if (command.includes("mode tier1")) apiCmd = "tier1";
    else if (command.includes("mode normal")) apiCmd = "normal";
    else if (command.includes("touch block")) apiCmd = "touch_block";
    else if (command.includes("touch unblock")) apiCmd = "touch_unblock";
    else if (command.includes("vpn connect")) apiCmd = "vpn_connect";
    else if (command.includes("vpn disconnect")) apiCmd = "vpn_disconnect";
    else if (command.includes("vpn open")) apiCmd = "vpn_open";
    else if (command.includes("droidspaces open")) apiCmd = "ds_open";
    else if (command.includes("droidspaces restart")) apiCmd = "ds_restart";
    else if (command.includes("trim")) apiCmd = "trim";
    else if (command.includes("fp clean")) apiCmd = "clean_tb";

    if (apiCmd) {
      const resp = await fetch(`/cgi-bin/api?cmd=${apiCmd}`);
      const text = await resp.text();
      return { errno: 0, stdout: text, stderr: "" };
    }
  } catch (err) {
    console.warn("HTTP API error:", err);
  }

  // 3. Fallback mock for local browser preview
  console.warn("Using mock data");
  return {
    errno: 0,
    stdout: JSON.stringify({
      mode: "tier1",
      ram: { total_mb: 7700, used_mb: 2250, free_mb: 4900, avail_mb: 5450 },
      battery: { temp: 31 },
      touch: { blocked: true, pid: "10516" },
      camera: { stopped: true },
      fingerprint: { killed: true },
      vpn: { connected: true, ip: "100.72.229.46" },
      droidspaces: { running: true }
    }),
    stderr: ""
  };
}

function toast(msg) {
  if (typeof ksu !== "undefined" && ksu.toast) {
    ksu.toast(msg);
  } else {
    console.log("Toast:", msg);
  }
}

// UI Elements
const elRamAvail = document.getElementById("ram-avail");
const elRamUsed = document.getElementById("ram-used");
const elRamFree = document.getElementById("ram-free");
const elRamTotal = document.getElementById("ram-total");
const elRamBar = document.getElementById("ram-bar");
const elBattTemp = document.getElementById("batt-temp");
const elTempDot = document.getElementById("temp-dot");
const elTempDesc = document.getElementById("temp-desc");
const elModeBadge = document.getElementById("current-mode-badge");
const elModeDesc = document.getElementById("mode-description");
const elBtnModeNormal = document.getElementById("btn-mode-normal");
const elBtnModeTier1 = document.getElementById("btn-mode-tier1");
const elBtnModeTier2 = document.getElementById("btn-mode-tier2");
const elVpnBadge = document.getElementById("vpn-badge");
const elVpnIp = document.getElementById("vpn-ip");
const elBtnToggleVpn = document.getElementById("btn-toggle-vpn");
const elBtnOpenVpn = document.getElementById("btn-open-vpn");
const elDsBadge = document.getElementById("ds-badge");
const elBtnOpenDs = document.getElementById("btn-open-ds");
const elBtnRestartDs = document.getElementById("btn-restart-ds");
const elToggleTouch = document.getElementById("toggle-touch");
const elTouchDesc = document.getElementById("touch-desc");
const elFpStatus = document.getElementById("fp-status");
const elCamStatus = document.getElementById("cam-status");
const elConsole = document.getElementById("console-output");
const elBtnRefresh = document.getElementById("btn-refresh");
const elBtnTrim = document.getElementById("btn-trim");
const elBtnCleanTb = document.getElementById("btn-clean-tb");
const elBtnClearLog = document.getElementById("btn-clear-log");

const elBtnScreenBack = document.getElementById("btn-screen-back");
const elBtnScreenHome = document.getElementById("btn-screen-home");
const elBtnScreenNormal = document.getElementById("btn-screen-normal");

let currentVpnConnected = false;

function appendLog(msg) {
  const time = new Date().toLocaleTimeString();
  elConsole.textContent += `\n[${time}] ${msg}`;
  elConsole.scrollTop = elConsole.scrollHeight;
}

function updateModeUI(mode) {
  [elBtnModeNormal, elBtnModeTier1, elBtnModeTier2].forEach(b => b.classList.remove("active"));
  
  if (mode === "tier2") {
    elBtnModeTier2.classList.add("active");
    elModeBadge.textContent = "TIER 2 (KIOSK)";
    elModeBadge.className = "badge badge-primary";
    elModeDesc.textContent = "Tier 2: Launcher3 frozen, status bars hidden. WebUI is the sole screen display.";
  } else if (mode === "tier1") {
    elBtnModeTier1.classList.add("active");
    elModeBadge.textContent = "TIER 1";
    elModeBadge.className = "badge badge-success";
    elModeDesc.textContent = "Tier 1: 29 bloat apps frozen & camera HAL halted. Full Android UI preserved.";
  } else {
    elBtnModeNormal.classList.add("active");
    elModeBadge.textContent = "NORMAL";
    elModeBadge.className = "badge badge-warning";
    elModeDesc.textContent = "Normal: Consumer phone mode with all Android services active.";
  }
}

// Fetch & render system metrics
async function refreshMetrics() {
  try {
    const res = await exec("frenzy-server json");
    if (!res.stdout) return;

    let data;
    try {
      data = JSON.parse(res.stdout);
    } catch {
      // Look for JSON block in output
      const jsonStart = res.stdout.indexOf("{");
      if (jsonStart >= 0) {
        data = JSON.parse(res.stdout.substring(jsonStart));
      } else {
        return;
      }
    }

    // Mode
    if (data.mode) {
      updateModeUI(data.mode);
    }

    // RAM
    if (data.ram) {
      const avail = data.ram.avail_mb || 0;
      const total = data.ram.total_mb || 7700;
      const used = data.ram.used_mb || 0;
      const free = data.ram.free_mb || 0;
      
      elRamAvail.textContent = `${avail} MB`;
      elRamUsed.textContent = `${used} MB`;
      elRamFree.textContent = `${free} MB`;
      elRamTotal.textContent = `${(total / 1024).toFixed(1)} GB`;

      const pct = Math.min(100, Math.round((avail / total) * 100));
      elRamBar.style.width = `${pct}%`;
    }

    // Battery & Thermal
    if (data.battery) {
      const temp = data.battery.temp || 0;
      elBattTemp.textContent = `${temp}°C`;
      if (temp >= 47) {
        elTempDot.className = "dot dot-danger";
        elTempDesc.textContent = "Overheat! Thermal guard throttled CPU";
      } else if (temp >= 42) {
        elTempDot.className = "dot dot-warning";
        elTempDesc.textContent = "Warm • Monitoring battery temperature";
      } else {
        elTempDot.className = "dot dot-success";
        elTempDesc.textContent = "Safe • Below 47°C throttle limit";
      }
    }

    // Tailscale VPN
    if (data.vpn) {
      currentVpnConnected = data.vpn.connected;
      if (data.vpn.connected) {
        elVpnBadge.textContent = "CONNECTED";
        elVpnBadge.className = "badge badge-success";
        elVpnIp.textContent = `IP: ${data.vpn.ip || "100.x.x.x"} (tun1)`;
        elBtnToggleVpn.textContent = "⚡ Disconnect";
        elBtnToggleVpn.style.color = "var(--danger)";
        elBtnToggleVpn.style.borderColor = "rgba(239, 68, 68, 0.3)";
        elBtnToggleVpn.style.background = "rgba(239, 68, 68, 0.12)";
      } else {
        elVpnBadge.textContent = "DISCONNECTED";
        elVpnBadge.className = "badge badge-warning";
        elVpnIp.textContent = "Tunnel offline";
        elBtnToggleVpn.textContent = "⚡ Connect VPN";
        elBtnToggleVpn.style.color = "var(--success)";
        elBtnToggleVpn.style.borderColor = "rgba(16, 185, 129, 0.3)";
        elBtnToggleVpn.style.background = "rgba(16, 185, 129, 0.12)";
      }
    }

    // Droidspaces
    if (data.droidspaces) {
      if (data.droidspaces.running) {
        elDsBadge.textContent = "RUNNING";
        elDsBadge.className = "badge badge-success";
      } else {
        elDsBadge.textContent = "STOPPED";
        elDsBadge.className = "badge badge-danger";
      }
    }

    // Touch Blocker status
    if (data.touch) {
      elToggleTouch.checked = data.touch.blocked;
      if (data.touch.blocked) {
        elTouchDesc.textContent = `Shield Active • Touch locked (PID: ${data.touch.pid})`;
      } else {
        elTouchDesc.textContent = "Normal touch active • Shield OFF";
      }
    }

    // Hardware Shields
    if (data.fingerprint) {
      elFpStatus.textContent = data.fingerprint.killed ? "KILLED & SHIELDED" : "ACTIVE";
    }

    if (data.camera) {
      elCamStatus.textContent = data.camera.stopped ? "HALTED" : "RUNNING";
    }

  } catch (err) {
    appendLog(`Metrics refresh error: ${err.message}`);
  }
}

// Mode Selector Click Handlers
elBtnModeNormal.addEventListener("click", async () => {
  appendLog("Switching to NORMAL mode...");
  toast("Restoring normal phone mode...");
  const res = await exec("frenzy-server mode normal");
  appendLog(res.stdout);
  updateModeUI("normal");
  await refreshMetrics();
  toast("Normal mode active!");
});

elBtnModeTier1.addEventListener("click", async () => {
  appendLog("Switching to TIER 1 (Smart Debloat)...");
  toast("Activating Tier 1 Debloat...");
  const res = await exec("frenzy-server mode tier1");
  appendLog(res.stdout);
  updateModeUI("tier1");
  await refreshMetrics();
  toast("Tier 1 Debloat active!");
});

elBtnModeTier2.addEventListener("click", async () => {
  appendLog("Switching to TIER 2 (Appliance Kiosk)...");
  toast("Activating Tier 2 Kiosk Display...");
  const res = await exec("frenzy-server mode tier2");
  appendLog(res.stdout);
  updateModeUI("tier2");
  await refreshMetrics();
  toast("Tier 2 Kiosk active!");
});

// Tailscale Controls
elBtnToggleVpn.addEventListener("click", async () => {
  if (currentVpnConnected) {
    appendLog("Disconnecting Tailscale VPN...");
    toast("Disconnecting VPN...");
    const res = await exec("frenzy-server vpn disconnect");
    appendLog(res.stdout);
  } else {
    appendLog("Connecting Tailscale VPN...");
    toast("Connecting VPN tunnel...");
    const res = await exec("frenzy-server vpn connect");
    appendLog(res.stdout);
  }
  await refreshMetrics();
});

elBtnOpenVpn.addEventListener("click", async () => {
  appendLog("Launching Tailscale App on screen...");
  await exec("frenzy-server vpn open");
});

// Droidspaces Controls
elBtnOpenDs.addEventListener("click", async () => {
  appendLog("Launching Droidspaces App on screen...");
  await exec("frenzy-server droidspaces open");
});

elBtnRestartDs.addEventListener("click", async () => {
  appendLog("Restarting Droidspaces container...");
  toast("Restarting container...");
  const res = await exec("frenzy-server droidspaces restart");
  appendLog(res.stdout);
  toast("Container restarted!");
  await refreshMetrics();
});

// Touch Blocker Toggle
elToggleTouch.addEventListener("change", async (e) => {
  const block = e.target.checked;
  if (block) {
    appendLog("Blocking touchscreen inputs (anti-ghost touch)...");
    toast("Blocking touchscreen...");
    const res = await exec("frenzy-server touch block");
    appendLog(res.stdout);
    toast("Touchscreen Blocked!");
  } else {
    appendLog("Unblocking touchscreen inputs...");
    toast("Unblocking touchscreen...");
    const res = await exec("frenzy-server touch unblock");
    appendLog(res.stdout);
    toast("Touchscreen Unblocked!");
  }
  await refreshMetrics();
});

// RAM Trim
elBtnTrim.addEventListener("click", async () => {
  appendLog("Executing RAM Quick Trim & cache compact...");
  toast("Compacting RAM & caches...");
  const res = await exec("frenzy-server trim");
  appendLog(res.stdout || "Trim executed.");
  await refreshMetrics();
  toast("RAM trimmed successfully!");
});

// Clean Tombstones
elBtnCleanTb.addEventListener("click", async () => {
  appendLog("Cleaning fingerprint crash tombstones...");
  const res = await exec("frenzy-server fp clean");
  appendLog(res.stdout);
  toast("Crash tombstones cleaned!");
  await refreshMetrics();
});

// Header Refresh & Clear Log
elBtnRefresh.addEventListener("click", async () => {
  elBtnRefresh.style.transform = "rotate(360deg)";
  appendLog("Refreshing metrics...");
  await refreshMetrics();
  setTimeout(() => { elBtnRefresh.style.transform = "none"; }, 500);
});

elBtnClearLog.addEventListener("click", () => {
  elConsole.textContent = "> Console cleared.";
});

// On-Screen Kiosk Navigation Handlers
if (elBtnScreenBack) {
  elBtnScreenBack.addEventListener("click", async () => {
    appendLog("Sending Android Back keyevent (4)...");
    toast("◀ Back");
    await exec("frenzy-server back");
  });
}

if (elBtnScreenHome) {
  elBtnScreenHome.addEventListener("click", async () => {
    appendLog("Refocusing FrenzyServer WebUI...");
    toast("🏠 WebUI Focused");
    await exec("frenzy-server home");
    await refreshMetrics();
  });
}

if (elBtnScreenNormal) {
  elBtnScreenNormal.addEventListener("click", async () => {
    appendLog("Exiting Kiosk & Restoring Normal Mode...");
    toast("Exiting Kiosk Mode...");
    const res = await exec("frenzy-server mode normal");
    appendLog(res.stdout);
    updateModeUI("normal");
    await refreshMetrics();
    toast("Normal mode restored!");
  });
}

// Init
window.addEventListener("DOMContentLoaded", () => {
  appendLog("FrenzyServer WebUI connected.");
  refreshMetrics();
  setInterval(refreshMetrics, 3500);
});

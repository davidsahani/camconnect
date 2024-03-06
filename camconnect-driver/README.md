# CamConnect Camera Driver

camconnect camera driver is a video input driver based on AVStream simulated hardware sample driver (Avshws). It provides a pin-centric [AVStream](https://docs.microsoft.com/windows-hardware/drivers/stream/avstream-overview) capture driver for a simulated piece of hardware. This streaming media driver performs video captures at 1280x720 pixels in RGB24 format using direct memory access (DMA) into capture buffers. 
This driver features enhanced parameter validation and overflow detection.

> [!WARNING]
> This driver has only been tested on Windows 10 x64. Use at your own risk.
>
> The developer does not accept liability for any consequences resulting from the use of this driver,
including but not limited to system crashes, data loss, or any other issues.
>
> By using this driver, you acknowledge and accept full responsibility for any potential damages or disruptions it may cause to your system or environment.

### Accessing the Driver

To interact with the CamConnect Camera Driver, you can utilize DirectShow, a multimedia framework provided by Microsoft for streaming media on Windows operating systems. 

This driver extends the filter with a custom property. Here are the specific details:

- **Property Set GUID**: {CB043957-7B35-456E-9B61-5513930F4D8E}
- **Property ID**: 0

The driver's custom property accepts an RGB buffer (1280x720 pixels), this buffer is then copied to the output buffer.

## Setting Up the Development Environment

1. Install [Visual Studio Community 2019](https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=Community&rel=16)

2. Install [WDK for Windows 10, version 2004](https://go.microsoft.com/fwlink/?linkid=2128854)

If you encounter any difficulty locating these downloads, you can access them through the [Other WDK downloads](https://learn.microsoft.com/en-us/windows-hardware/drivers/other-wdk-downloads) page. Alternatively, visit [Visual Studio Older Downloads](https://my.visualstudio.com/Downloads?q=visual%20studio%202019&wt.mc_id=o~msft~vscom~older-downloads) and search for the specified versions to download them directly.

When you install Visual Studio 2019, select the Desktop development with C++ workload, then under "Individual Components" add the following components based on your requirements:

- MSVC v142 - VS 2019 C++ ARM64/ARM64EC Spectre-mitigated libs (Latest)
- MSVC v142 - VS 2019 C++ x64/x86 Spectre-mitigated libs (Latest)
- C++ ATL for latest v142 build tools with Spectre Mitigations (ARM64/ARM64EC)
- C++ ATL for latest v142 build tools with Spectre Mitigations (x86 & x64)
- C++ MFC for latest v142 build tools with Spectre Mitigations (ARM64/ARM64EC)
- C++ MFC for latest v142 build tools with Spectre Mitigations (x86 & x64)

**Hint**: Use the Search box to look for "64 latest spectre" to quickly see these components.

**Important**: Ensure Windows 10 SDK version 10.0.19041.0 is installed. If not, add it via Visual Studio Installer > "Individual Components". Also, confirm SDK and WDK versions match.

## Building The Driver

1. Open the driver solution in Visual Studio

    In Visual Studio, click *File* \> *Open* \> *Project/Solution...* and navigate to the folder that contains the project files. Double-click the **camconnect.sln** file.

    Alternatively, run Visual Studio, and from the **File** menu, select **Open**, then **Project/Solution...**, navigate to the project directory, and select **camconnect.vcxproj** (the VC++ Project).

    In the **Solution Explorer** pane in Visual Studio, at the top is **Solution 'camconnect'**. Right-click this and select **Configuration Manager**. Follow the instructions in [Building a Driver with Visual Studio and the WDK](https://docs.microsoft.com/windows-hardware/drivers/develop/building-a-driver) to set the platform, operating system, and debug configuration you want to use, and to build the driver. This driver project will automatically sign the driver package.

2. Build the project using Visual Studio

    In Visual Studio, click *Build* \> *Build Solution*.

## Installing the driver

Firstly, ensure that test signing is enabled. To do this:

1. Open a Command Prompt window as Administrator.
2. Enter the following command: bcdedit /set TESTSIGNING ON
3. Reboot the computer.

> [!IMPORTANT]
> Before using BCDEdit to change boot information you may need to temporarily suspend Windows security features such as BitLocker and Secure Boot on the test PC.

Re-enable these security features when testing is complete and appropriately manage the test PC, when the security features are disabled.

Here's how to install the driver:

1. Open the `Add Hardware Wizard` by running `hdwwiz` via the Run command.
2. In the wizard, click "Next" and select "Install the hardware that I manually select from a list (Advanced)" in the next section.
3. Click "Next" again and choose "Have Disk" in the subsequent section.
4. In the dialog box, click "Browse" and navigate to the location of the driver build folder and select `camconnect.inf`.

After installation, you should be able to locate the `camconnect camera driver` in Device Manager under `Cameras`. 

## Driver code hierarchy

[**DriverEntry**](https://docs.microsoft.com/previous-versions//ff558717(v=vs.85)) in Device.cpp is the initial point of entry into the driver. This routine passes control to AVStream by calling the [**KsInitializeDriver**](https://docs.microsoft.com/windows-hardware/drivers/ddi/content/ks/nf-ks-ksinitializedriver) function. In this call, the minidriver passes the device descriptor, an AVStream structure that recursively defines the AVStream object hierarchy for a driver. This is common behavior for an AVStream minidriver.

At device start time, a simulated piece of capture hardware is created (the **CHardwareSimulation** class), and a DMA adapter is acquired from the operating system and is registered with AVStream by calling the [**KsDeviceRegisterAdapterObject**](https://docs.microsoft.com/windows-hardware/drivers/ddi/content/ks/nf-ks-ksdeviceregisteradapterobject) function. This call is required for a driver that performs DMA access directly into the capture buffers, instead of using DMA access to write to a common buffer. The driver creates the [KS Filter](https://docs.microsoft.com/windows-hardware/drivers/stream/ks-filters) for this device dynamically by calling the [**KsCreateFilterFactory**](https://docs.microsoft.com/windows-hardware/drivers/ddi/content/ks/nf-ks-kscreatefilterfactory) function.

Filter.cpp is where the driver lays out the [**KSPIN\_DESCRIPTOR\_EX**](https://docs.microsoft.com/windows-hardware/drivers/ddi/content/ks/ns-ks-_kspin_descriptor_ex) structure for the single video pin. In addition, a [**KSFILTER\_DISPATCH**](https://docs.microsoft.com/windows-hardware/drivers/ddi/content/ks/ns-ks-_ksfilter_dispatch) structure and a [**KSFILTER\_DESCRIPTOR**](https://docs.microsoft.com/windows-hardware/drivers/ddi/content/ks/ns-ks-_ksfilter_descriptor) structure are provided in this source file. The filter dispatch provides only a create dispatch, a routine that is included in Filter.cpp. The process dispatch is provided on the pin because this is a pin-centric driver.

Capture.cpp contains source for the video capture pin on the capture filter. This is where the [**KSPIN\_DISPATCH**](https://docs.microsoft.com/windows-hardware/drivers/ddi/content/ks/ns-ks-_kspin_dispatch) structure for the unique pin is provided. This dispatch structure specifies a *Process* callback routine, also defined in this source file. This routine is where stream pointer manipulation and cloning occurs.

The process callback is one of two routines of interest in Capture.cpp that demonstrate how to perform DMA transfers with AVStream functionality. The other is the **CCapturePin::CompleteMappings** method. These two methods show how to use the queue, obtain clone pointers, use scatter/gather lists, and perform other DMA-related tasks.

For more information, see the comments in all .cpp files.

## File manifest

| File | Description |
| --- | --- |
| common.h | Main header file for the driver |
| camconnect.inf | Driver installation file |

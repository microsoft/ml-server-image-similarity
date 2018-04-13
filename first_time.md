---
layout: default
title: HOME
---

## Azure AI Gallery Deployment

If you deployed this solution from the [Azure AI Gallery]({{ site.aka_url }}), there is one final step to complete once you log onto the VM. The command prompt will be open on the VM, and you must respond YES to download images and complete the solution workflow.  

<img src="images/prompt.png" > 

If you close this window or do not respond with a `YES`, your `ImageSimilarity_Py` database will be present but all the tables will be empty. In this case, you can execute the file **LoadImageData.ps1** in the **C:\Solutions\ImageSimilarity\resources\ActionScripts** directory to complete the last step.





---
layout: post
tags: [azure, Azure Virtual Desktop, AVD]
title: How to reset AVD Host Pool Counter
excerpt_separator: <!--more-->
---
Do you know how to reset Host Pool counter when adding new VMs to the pool, without deleting existing hosts?
No? Then this post is for you! 

![AVD]({{ site.baseurl }}/assets/img/blog/2021-06-24-AVDResetHostpoolCount/hpcounter3.PNG)

<!--more-->
This is a quick post related to the Azure Virtual Desktop Host Pool update process. Microsoft currently recommends rebuilding the session host from the latest, fully patched image stored in Shared Image Galery (SIG). This is an overall smooth and easy process however the issue I've had was around the host prefix counter. Every new host added to the pool gets an incremental number unless you delete all the session hosts from the pool. 
In my case, I didn't want to delete the host in case I need to roll back and a customer wanted the host numbers to start from 0-10. 
The solution to this is pretty simple, modify the ARM Template before hitting Create button.
Follow the normal process of adding a new host to the host pool but at the very last step, instead of clicking Create, click on Download a template for automation

![AVD]({{ site.baseurl }}/assets/img/blog/2021-06-24-AVDResetHostpoolCount/hpcounter1.PNG)

+ Now select Parameters 

![AVD]({{ site.baseurl }}/assets/img/blog/2021-06-24-AVDResetHostpoolCount/hpcounter2.PNG)

+ now look for vmInitialNumber

![AVD]({{ site.baseurl }}/assets/img/blog/2021-06-24-AVDResetHostpoolCount/hpcounter3.PNG)

+ Change the value from 1, in my case, to 0 or any other number that you want to start VM numbers from.
+ Now click Deploy.

That's it!

IMPORTANT: Remember to copy the Registration Token as you will need it to finish Deployment!

Thanks for reading! 


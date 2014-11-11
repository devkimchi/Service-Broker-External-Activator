# Service Broker External Activator for SQL Server Step by Step #1 #

In SQL Server, unlike [triggers](http://msdn.microsoft.com/en-us/library/ms178110(v=sql.110).aspx), Service Broker (SB) works asynchronously. The benefits of using SB can be found in [this document](http://msdn.microsoft.com/en-us/library/ms171578(v=sql.105).aspx). One of great benefits using SB is that it is not only comsumed within SQL Server, but also it calls an application outside the SQL Server through External Activator (EA). There are many relevant articles for SB and internal activator. But it is hard to find some useful EA related documents.

Basically, this series of articles are based on several resources including [Announcing Service Broker External Activator](http://blogs.msdn.com/b/sql_service_broker/archive/2008/11/21/announcing-service-broker-external-activator.aspx), [Get Started With Using External Activator](http://blogs.msdn.com/b/sql_service_broker/archive/2009/05/18/get-started-with-using-external-activator.aspx), [Sample activated application](http://blogs.msdn.com/b/sql_service_broker/archive/2010/03/10/sample-activated-application.aspx), and [Auditing Data Changes in SQL Server using Service Broker's External Activator](http://ajitananthram.wordpress.com/2012/05/26/auditing-external-activator). Throughout these posts, you will get used to SB and EA.

Its sample source codes can be found at: [devkimchi/Service-Broker-External-Activator](https://github.com/devkimchi/Service-Broker-External-Activator)

> * **Step 1: Service Broker External Activator Service Setup**
> * [Step 2: SQL Server Setup](http://devkimchi.com/831/service-broker-external-activator-for-sql-server-step-by-step-2/)
> * [Step 3: External Activator Application Development](http://devkimchi.com/891/service-broker-external-activator-for-sql-server-step-by-step-3/)
> * [Step 4: External Activator Service Configuration](http://devkimchi.com/951/service-broker-external-activator-for-sql-server-step-by-step-4/)
> * [Step 5: Putting Them Altogether](http://devkimchi.com/1051/service-broker-external-activator-for-sql-server-step-by-step-5/)

In this article, we are going to install Service Broker External Activator Service.
 

## External Activator Service Setup for Service Broker ##


### Installing Windows Service ###

Depending on your SQL Server version and architecture, you can choose one of followings:

* [Microsoft® SQL Server® 2008 R2 Feature Pack](http://www.microsoft.com/en-us/download/details.aspx?id=16978)
* [Microsoft® SQL Server® 2012 Feature Pack](http://www.microsoft.com/en-us/download/details.aspx?id=29065)

In this post, we are using SQL Server 2012. When you click the link above, you can expand the `Install Instruction` section and find **Service Broker External Activator**. From there you can choose either x86 package, x64 package or IA64 package. Select a package best suits for your environment.

During the installation, you will see a screen like below:

![](http://blob.devkimchi.com/devkimchiwp/2014/11/SSBEAS.Install.01.png)

Choose **Built-in Account** and `NETWORK SERVICE` for now. Once it is installed, open the `Services` window on Control Panel. Then you can find the Windows Service installed.

![](http://blob.devkimchi.com/devkimchiwp/2014/11/SSBEAS.Install.02.png)


### Changing Log On Account to Virtual Account ###

It's not started yet. Before manually starting this Service, we need to change its log on account. It has been currently bound with `NETWORK SERVICE` but this is not right. For Windows 7, Windows Server 2008 or later, you might have heard of the term, **Virtual Account**. This is not a real account but to work as like a service account in Windows 7, Windows Server 2008 or later which is not on Active Directory. As we have already installed Service Broker External Activator Service, we have a virtual account called, `NT SERVICE\SSBExternalActivator`. So, we can simply change the log on account to this, without password.

![](http://blob.devkimchi.com/devkimchiwp/2014/11/SSBEAS.Install.03.png)


### Granting Permissions to Virtual Account on Application Directory ###

We need more job to do to start this service. The Windows Service has been installed at `C:\Program Files\Service Broker\External Activator`. Therefore, the directory should be accessible for the virtual account.

**(This is optional)** Find the `SSB EA Admin` account group from `Local users and Groups` and add a service account to run the Windows Service. If you want to use the virtual account only, this is not necessary.

![](http://blob.devkimchi.com/devkimchiwp/2014/11/SSBEAS.Install.04.png)

Allow `Full Control` onto the `SSB EA Admin` account group and the virtual account, `NT SERVICE\SSBExternalActivator`.

![](http://blob.devkimchi.com/devkimchiwp/2014/11/SSBEAS.Install.05.png)


---
Now, we are ready to run this Windows Service. Before starting the service, we need to setup SQL Server first. In the next post, [Step 2: SQL Server Setup](http://devkimchi.com/831/service-broker-external-activator-for-sql-server-step-by-step-2/), we will setup SQL Server to enable SB.

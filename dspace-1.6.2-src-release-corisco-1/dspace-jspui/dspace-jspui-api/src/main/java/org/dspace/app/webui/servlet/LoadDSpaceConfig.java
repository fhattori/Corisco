/*
 * LoadDSpaceConfig.java
 *
 * Version: $Revision: 3705 $
 *
 * Date: $Date: 2009-04-11 17:02:24 +0000 (Sat, 11 Apr 2009) $
 *
 * Copyright (c) 2002-2005, Hewlett-Packard Company and Massachusetts
 * Institute of Technology.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * - Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * - Neither the name of the Hewlett-Packard Company nor the name of the
 * Massachusetts Institute of Technology nor the names of their
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package org.dspace.app.webui.servlet;

import org.dspace.core.ConfigurationManager;

import javax.servlet.http.HttpServlet;
import java.net.URL;
import java.net.URLConnection;

/**
 * Simple servlet to load in DSpace and log4j configurations. Should always be
 * started up before other servlets (use <loadOnStartup>)
 * 
 * This class holds code to be removed in the next version of the DSpace XMLUI,
 * it is now managed by a Shared Context Listener inthe dspace-api project.
 * 
 * It is deprecated, rather than removed to maintain backward compatibility for
 * local DSpace 1.5.x customized overlays.
 * 
 * TODO: Remove in trunk
 *
 * @deprecated Use Servlet Context Listener provided in dspace-api (remove in >
 *             1.5.x)
 * @author Robert Tansley
 * @version $Revision: 3705 $
 */
public class LoadDSpaceConfig extends HttpServlet
{	
    public void init()
    {
        // On Windows, URL caches can cause problems, particularly with undeployment
        // So, here we attempt to disable them if we detect that we are running on Windows
        try
        {
            String osName = System.getProperty("os.name");
            if (osName != null)
                osName = osName.toLowerCase();

            if (osName != null && osName.contains("windows"))
            {
                URL url = new URL("http://localhost/");
                URLConnection urlConn = url.openConnection();
                urlConn.setDefaultUseCaches(false);
            }
        }
        catch (Throwable t)
        {
            // Any errors thrown in disabling the caches aren't significant to
            // the normal execution of the application, so we ignore them
        }

        if(!ConfigurationManager.isConfigured())
        {
            // Get config parameter
            String config = getServletContext().getInitParameter("dspace-config");

            // Load in DSpace config
            ConfigurationManager.loadConfig(config);
        }

    }
}

using System;
using System.Collections.Generic;
using System.Net.Http;
using EnvDTE;
using Microsoft.VisualStudio.TemplateWizard;

namespace Wizards
{
    class VCPKGHash : IWizard
    {
        private const string s_MinimumVCPKGHash = "ce613c41372b23b1f51333815feb3edd87ef8a8b"; // 2025.04.09

        public void RunStarted(object automationObject, Dictionary<string, string> replacementsDictionary, WizardRunKind runKind, object[] customParams)
        {
            string hash = s_MinimumVCPKGHash;

            try
            {
                // Get hash from https://api.github.com/repos/microsoft/vcpkg/git/refs/heads
                using (var handler = new HttpClientHandler())
                {
                    handler.UseDefaultCredentials = true;
                    using (var client = new HttpClient(handler))
                    {
                        client.BaseAddress = new Uri("https://api.github.com");
                        client.DefaultRequestHeaders.Add("User-Agent", "Other");
                        var response = client.GetAsync("repos/microsoft/vcpkg/git/refs/heads").GetAwaiter().GetResult();
                        if (response.IsSuccessStatusCode)
                        {
                            var responseContent = response.Content;
                            string result = responseContent.ReadAsStringAsync().GetAwaiter().GetResult();
                            int start = result.IndexOf(@"""sha"":", 0);
                            if (start != -1)
                            {
                                int stringStart = result.IndexOf("\"", start + 6);
                                if (stringStart != -1)
                                {
                                    int stringEnd = result.IndexOf("\"", stringStart + 1);
                                    if (stringEnd != -1)
                                    {
                                        string value = result.Substring(stringStart, (stringEnd - stringStart + 1));

                                        hash = value.Trim('"');
                                    }
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception)
            {
                // If it fails in any way, just use the hard-coded minimum.
                hash = s_MinimumVCPKGHash;
            }

            replacementsDictionary["$vcpkghash$"] = hash;
        }

        public void ProjectFinishedGenerating(Project project)
        {
        }

        public bool ShouldAddProjectItem(string filePath) { return true; }

        public void ProjectItemFinishedGenerating(ProjectItem projectItem)
        {
        }

        public void RunFinished()
        {
        }

        public void BeforeOpeningFile(ProjectItem projectItem)
        {
        }
    }
}


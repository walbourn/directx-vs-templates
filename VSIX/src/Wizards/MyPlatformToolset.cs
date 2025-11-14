using System.Collections.Generic;
using System.Windows.Forms;
using EnvDTE;
using Microsoft.VisualStudio.TemplateWizard;

namespace Wizards
{
    public class MyPlatformToolset : IWizard
    {
        public void RunStarted(object automationObject, Dictionary<string, string> replacementsDictionary, WizardRunKind runKind, object[] customParams)
        {
            var dte2 = (EnvDTE80.DTE2)automationObject;

            string regRoot = dte2.RegistryRoot.ToUpperInvariant();

            if (regRoot.StartsWith(@"SOFTWARE\MICROSOFT\VISUALSTUDIO\18.0"))
            {
                replacementsDictionary["$platformtoolset$"] = "v145";
                replacementsDictionary["$targetplatformversion$"] = "10.0";
            }
            else if (regRoot.StartsWith(@"SOFTWARE\MICROSOFT\VISUALSTUDIO\17.0"))
            {
                replacementsDictionary["$platformtoolset$"] = "v143";
                replacementsDictionary["$targetplatformversion$"] = "10.0";
            }
            else if (regRoot.StartsWith(@"SOFTWARE\MICROSOFT\VISUALSTUDIO\16.0"))
            {
                replacementsDictionary["$platformtoolset$"] = "v142";
                replacementsDictionary["$targetplatformversion$"] = "10.0";
            }
            else
            {
                MessageBox.Show(string.Format("ERROR: Unrecognized Visual Studio version\n{0}\n{1}", dte2.Version, regRoot),
                    "Direct3D Game Wizard", MessageBoxButtons.OK, MessageBoxIcon.Stop);
            }
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

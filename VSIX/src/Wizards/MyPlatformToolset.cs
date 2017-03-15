using System.Collections.Generic;
using System.Windows;
using EnvDTE;
using Microsoft.VisualStudio.TemplateWizard;

namespace Wizards
{
    class MyPlatformToolset : IWizard
    {
        public void RunStarted(object automationObject, Dictionary<string, string> replacementsDictionary, WizardRunKind runKind, object[] customParams)
        {
            var dte2 = (EnvDTE80.DTE2)automationObject;

            string regRoot = dte2.RegistryRoot.ToUpperInvariant();

            if (regRoot.StartsWith(@"SOFTWARE\MICROSOFT\VISUALSTUDIO\15.0"))
            {
                replacementsDictionary["$platformtoolset$"] = "v141";
            }
            else if (regRoot.StartsWith(@"SOFTWARE\MICROSOFT\VISUALSTUDIO\14.0"))
            {
                replacementsDictionary["$platformtoolset$"] = "v140";
            }
            else
            {
                MessageBox.Show(string.Format("ERROR: Unrecognized Visual Studio version\n{0}\n{1}", dte2.Version, regRoot),
                    "Direct3D Game Wizard", MessageBoxButton.OK, MessageBoxImage.Stop);
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


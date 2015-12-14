
import UIKit

extension UITabBarController{
    func isTabBarHidden() -> Bool{
        let viewFrame = CGRectApplyAffineTransform(self.view.frame, self.view.transform)
        let tabBarFrame = self.tabBar.frame
        return tabBarFrame.origin.y >= viewFrame.size.height
    }
    
    func setTabBarHidden(hidden:Bool){
        self.setTabBarHidden(hidden, animated: false)
    }
    
    func setTabBarHidden(hidden:Bool, animated:Bool){
        let isHidden = self.isTabBarHidden()
        if (hidden == isHidden){
            return
        }
        
        if let transitionView:UIView = self.view.subviews[0]{
            let viewFrame:CGRect = CGRectApplyAffineTransform(self.view.frame, self.view.transform)
            var tabBarFrame:CGRect = self.tabBar.frame
            var containerFrame:CGRect = transitionView.frame


            tabBarFrame.origin.y = CGFloat(viewFrame.size.height - (hidden ? 0 : tabBarFrame.size.height))

            

            containerFrame.size.height = CGFloat( viewFrame.size.height - (hidden ? 0 : tabBarFrame.size.height) )
            UIView.animateWithDuration(0.3, animations: {
                self.tabBar.frame = tabBarFrame
                transitionView.frame = containerFrame
            })
        }
        
    }
}
/*


        - (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated {

            
            if (!transitionView)
            {
                #if DEBUG
                    NSLog(@"could not get the container view!");
                    #endif
                    return;
                }
                

                }
                ];
}

*/
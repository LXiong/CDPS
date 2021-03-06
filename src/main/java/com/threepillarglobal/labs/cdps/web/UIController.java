package com.threepillarglobal.labs.cdps.web;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;

import javax.ws.rs.QueryParam;

import org.joda.time.DateTime;
import org.joda.time.Seconds;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.threepillarglobal.labs.cdps.domain.CardioRisk;
import com.threepillarglobal.labs.cdps.domain.DemographicReport;
import com.threepillarglobal.labs.cdps.domain.User;
import com.threepillarglobal.labs.cdps.service.api.ChartService;
import com.threepillarglobal.labs.cdps.service.api.ReportService;
import com.threepillarglobal.labs.cdps.service.api.RiskService;
import com.threepillarglobal.labs.cdps.service.api.UserService;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;

@Controller
public class UIController {

    private static DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");

    @Autowired
    @Qualifier(value = "chartServiceMock")
    private ChartService chartService;

    @Autowired
    //@Qualifier(value = "riskFactorServiceMock")
    @Qualifier(value = "riskFactorServiceImpl")
    private RiskService riskFactorsService;

    @Autowired
    //@Qualifier(value = "userServiceMock")
    @Qualifier(value = "userServiceImpl")
    private UserService userService;
    private static List<User> userList;

    @Autowired
    @Qualifier(value = "reportServiceImpl")
    private ReportService reportService;
    
    /*@PostConstruct
    public void init() {
    	DateTime b = new DateTime(Calendar.getInstance().getTime());
        userList = userService.getUsers();
        DateTime e = new DateTime(Calendar.getInstance().getTime());
        System.out.println("!!! User list size: " + userList.size() + " retrieved in " + Seconds.secondsBetween(b, e).getSeconds() % 60 + " seconds");
        System.out.println(userList.get(0).toString());
    }*/

    @RequestMapping(value = "/getUid", method = RequestMethod.GET)
    public @ResponseBody
    List<User> getTags(@RequestParam String userName) {
    	if (userList==null)
    	{
    		DateTime b = new DateTime(Calendar.getInstance().getTime());
            userList = userService.getUsers();
            DateTime e = new DateTime(Calendar.getInstance().getTime());
            System.out.println("Caching: " + userList.size() + "users. <retrieved in " + Seconds.secondsBetween(b, e).getSeconds() % 60 + " seconds>");            
    	}
    	
        List<User> result = new ArrayList<User>();
        // iterate a list and filter by userName
        for (User user : userList) {
            if (user.getPersonalData().getName().contains(userName)) {
                result.add(user);
            }
        }
        return result;
    }

    @RequestMapping(value = "/getRiskData", method = RequestMethod.GET)
    public @ResponseBody
    CardioRisk getRiskData(@RequestParam String uid, @QueryParam("from") String from, @QueryParam("to") String to) {
        try {
            Date sDate = dateFormat.parse(from);
            Date eDate = dateFormat.parse(to);
            //System.err.println("+++ From: " + sDate + " To: " + eDate);
            return riskFactorsService.getCardioRisk(uid, sDate, eDate);
        } catch (ParseException e) {
            e.printStackTrace();
        }
        return new CardioRisk();
    }

    @RequestMapping(value = "/displayReport", method = RequestMethod.GET)
    public @ResponseBody
    List<DemographicReport> displayReport() {
    	return reportService.display();
    }
    
}

/*
Module : AADate.h
Purpose: Implementation for the algorithms which convert between the Gregorian and Julian calendars and the Julian Day
Created: PJN / 29-12-2003
History: PJN / 10-11-2004 1. Fix for CAADate::Get so that it works correctly for propalactive calendar dates
         PJN / 15-05-2005 1. Fix for CAADate::Set(double JD, bool bGregorianCalendarCalendar) not setting the m_bGregorianCalendarCalendar
                          member variable correctly.
         PJN / 26-01-2006 1. After a bug report from Ing. Taras Kapuszczak that a round trip of the date 25 January 100 as
                          specified in the Gregorian calendar to the Julian day number and then back again produces the
                          incorrect date 26 January 100, I've spent some time looking into the 2 key Meeus Julian Day
                          algorithms. It seems that the algorithms which converts from a Calendar date to JD works ok for
                          propalactive dates, but the reverse algorithm which converts from a JD to a Calendar date does not.
                          Since I made the change in behaviour to support propalactive Gregorian dates to address issues
                          with the Moslem calendar (and since then I have discovered further unresolved bugs in the Moslem
                          calendar algorithms and advised people to check out my AA+ library instead), I am now reverting
                          these changes so that the date algorithms are now as presented in Meeus's book. This means that
                          dates after 15 October 1582 are assumed to be in the Gregorian calendar and dates before are
                          assumed to be in the Julian calendar. This change also means that some of the CAADate class
                          methods no longer require the now defunct "bool" parameter to specify which calendar the date
                          represents. As part of the testing for this release verification code has been added to AATest.cpp
                          to test all the dates from JD 0 (i.e. 1 January -4712) to a date long in the future. Hopefully
                          with this verification code, we should have no more reported issues with the class CAADate. Again
                          if you would prefer a much more robust and comprehensive Date time class framework, don't forget
                          to check out the authors DTime+ library.
                          2. Optimized CAADate constructor code
                          3. Provided a static version of CAADate::DaysInMonth() method
                          4. Discovered an issue in CAADate::JulianToGregorian. It seems the algorithm presented in the
                          book to do conversion from the Julian to Gregorian calendar fails for Julian dates before the
                          Gregorian calendar reform in 1582. I have sent an email to Jean Meeus to find out if this is a
                          bug in my code or a deficiency in the algorithm presented. Currently the code will assert in this
                          function if it is called for a date before the Gregorian reform.
         PJN / 27-01-2007 1. The static version of the Set method has been renamed to DateToJD to avoid any confusion with
                          the other Set methods. Thanks to Ing. Taras Kapuszczak for reporting this issue.
                          2. The method InGregorianCalendar has now also been renamed to the more appropriate
                          AfterPapalReform.
                          3. Reinstated the bGregorianCalendar parameter for the CAADate constructors and Set methods.
                          4. Changed the parameter layout for the static version of DaysInMonth
                          5. Addition of a InGregorianCalendar method.
                          6. Addition of a SetInGregorianCalendar method.
                          7. Reworked implementation of GregorianToJulian method.
                          8. Reworked implementation of JulianToGregorian method.
         PJN / 07-02-2009 1. Updated the static version of CAADate::DaysInMonth to compile cleanly using code analysis
         PJN / 29-03-2015 1. Fixed up some variable initializations around the use of modf. Thanks to Arnaud Cueille for
                          reporting this issue.
         PJN / 18-02-2017 1. Reworked the CAADate::SetInGregorianCalendar method to use the AfterPapalReform method.
         PJN / 18-04-2020 1. Made a number of the CAADate methods [[nodiscard]] when compiled as C++ 17
         PJN / 29-04-2020 1. Fixed a compilation issue on GCC where size_t was undefined in various modules. Thanks to
                          Bert Devlieghe for reporting this bug.
         PJN / 03-10-2021 1. Renamed CAADate::DAY_OF_WEEK type to DOW.
         PJN / 22-03-2022 1. Fixed an issue in CAADate::DayOfWeek for dates which are close to or prior to the Julian
                          day epoch. Thanks to "znight" for reporting this issue.
                          2. Updated all the code in the AADate.cpp to use C++ uniform initialization for all variable
                          declarations.
         PJN / 21-12-2024 1. Fixed a compiler warning in CAADate::DayOfWeek when using Clang.
         PJN / 10-01-2026 1. Updated CAADate::Get to handle JD values < 0. Internally now the CAADate class uses the
                          Howard Hinnant's algorithms at http://howardhinnant.github.io/date_algorithms.html as their
                          basis instead of the algorithms as presented in Meeus's book. This is because the Meeus's
                          algorithms do not work with negative Julian dates. This means that CAADate can now fully
                          support propalactive calendar dates in both the Julian and Gregorian calendars.
                          2. Introduced the concept of a null or invalid CAADate. This means that an instance of
                          CAADate can be used to represent an invalid, undefined or null date. A new CAADate::IsValid
                          method has been added to get this state.
                          3. Fully implemented the gang of 6 for the CAADate class.
                          4. The CAADate::IsLeap method is now constexpr and has been optimized.
                          5. The CAADate::InGregorianCalendar method is now constexpr
                          6. Reworked the CAADate constructors to use constructor delegation
                          7. The CAADate::DayOfWeek method has been optimized.
                          8. The CAADate::DaysInMonth method has been optimized.
         PJN / 11-01-2026 1. Made the whole CAADate class constexpr.
         PJN / 12-01-2026 1. Fixed an issue with the CAADate::INT method where it would return wrong values for 
                          negative integer values. Thanks to "znight" for reporting this issue.
         PJN / 11-04-2026 1. Fixed an issue with the CAADate::Get where it would incorrectly calculate Hour values
                          for dates at exactly midnight before the Unix epoch. Thanks to "Pavel" for reporting this
                          bug.
                          2. Added validation code to CAADate::DateToJDGregorian and CAADate::DateToJDJulian to now 
                          not allow a Day parameter less than 1. Thanks to "Pavel" for reporting this issue.
         PJN / 01-06-2026 1. Fixed a bug in the CAADate::DayOfWeek method where it would return the wrong week
                          day for some dates prior to 1 January 1970. Thanks to Buenyamin Olgun for reporting this 
                          issue.
         PJN / 09-09-2026 1. Fix compile problems in AADate.h when "Windows.h" is also included. When you include 
                          "Windows.h", this causes known compilation issues when using std::numeric_limits<T>::min in
                          your code. The CAADate code now uses "nan" in the CAADate constructor, CAADate::SetInvalid 
                          and CAADate::IsValid methods to indicate an invalid CAADate instance. Thanks to "znight" 
                          for reporting this issue.

Copyright (c) 2003 - 2026 by PJ Naughter (Web: www.naughter.com, Email: pjna@naughter.com)

All rights reserved.

Copyright / Usage Details:

You are allowed to include the source code in any product (commercial, shareware, freeware or otherwise) 
when your product is released in binary form. You are allowed to modify the source code in any way you want 
except you cannot modify the copyright details at the top of each module. If you want to distribute source 
code with your application, then you are only allowed to distribute versions released by the author. This is 
to maintain a single distribution point for the source code. 

*/


//////////////////// Macros / Defines /////////////////////////////////////////

#if _MSC_VER > 1000
#pragma once
#endif //#if _MSC_VER > 1000

#ifndef __AADATE_H__
#define __AADATE_H__

#ifndef AAPLUS_EXT_CLASS
#define AAPLUS_EXT_CLASS
#endif //#ifndef AAPLUS_EXT_CLASS


//////////////////// Includes /////////////////////////////////////////////////

#include <cmath>
#include <cassert>
#include <array>
#include <limits>


//////////////////// Classes //////////////////////////////////////////////////

class AAPLUS_EXT_CLASS CAACalendarDate
{
public:
//Member variables
  long Year{0};
  long Month{0};
  long Day{0};
};

class AAPLUS_EXT_CLASS CAADate
{
protected:
//Methods
  constexpr static void JDToDMYGregorian(long Days, long& Year, long& Month, long& Day) noexcept
  {
    //Validate our parameters
    static_assert(std::numeric_limits<unsigned>::digits >= 18, "This algorithm has not been ported to a 16 bit unsigned integer");
    static_assert(std::numeric_limits<long>::digits >= 20, "This algorithm has not been ported to a 16 bit signed integer");

    Days += 719468;
    const long era{(Days >= 0 ? Days : Days - 146096) / 146097};
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    const auto doe{static_cast<unsigned>(Days - (era * 146097))};
    const auto yoe{(doe - (doe / 1460) + (doe / 36524) - (doe / 146096)) / 365};
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    const auto y{static_cast<long>(yoe) + era * 400};
    const unsigned doy{doe - ((365 * yoe) + (yoe / 4) - (yoe / 100))};
    const unsigned mp{((5 * doy) + 2) / 153};
    const unsigned d{doy - ((153 * mp) + 2) / 5 + 1};
    const unsigned m{mp + ((mp < 10) ? 3 : -9)};
    Year = y + (m <= 2);
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    Month = static_cast<long>(m);
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    Day = static_cast<long>(d);
  }

  constexpr static void JDToDMYJulian(long Days, long& Year, long& Month, long& Day) noexcept
  {
    //Valiudate our parameters
    static_assert(std::numeric_limits<long>::digits >= 20, "This algorithm has not been ported to a 16 bit signed integer");

    Days += 719470;
    const long era{((Days >= 0) ? Days : (Days - 1460)) / 1461};
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    const auto doe{static_cast<unsigned>(Days - (era * 1461))};
    const auto yoe{(doe - (doe / 1460)) / 365};
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    const auto y{static_cast<long>(yoe) + (era * 4)};
    const unsigned doy{doe - (365 * yoe)};
    const unsigned mp{((5 * doy) + 2) / 153};
    const unsigned d{doy - (((153 * mp) + 2) / 5) + 1};
    const unsigned m{mp + ((mp < 10) ? 3 : -9)};
    Year = y + (m <= 2);
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    Month = static_cast<long>(m);
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    Day = static_cast<long>(d);
  }

  constexpr static bool DateToJDGregorian(long Year, long month, long Day, long& Days) noexcept
  {
    //Validate our parameters
    static_assert(std::numeric_limits<unsigned>::digits >= 18, "This algorithm has not been ported to a 16 bit unsigned integer");
    static_assert(std::numeric_limits<long>::digits >= 20, "This algorithm has not been ported to a 16 bit signed integer");
    if ((month < 1) || (month > 12) || (Day < 1) || (Day > DaysInMonth(month, IsLeap(Year, true))))
      return false;

    if (month <= 2)
      --Year;
    long era{((Year >= 0) ? Year : Year - 399) / 400};
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    const auto yoe{static_cast<unsigned>(Year - (era * 400))};
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    const auto doy{static_cast<unsigned>((153 * (month + ((month > 2) ? -3 : 9)) + 2) / 5 + Day - 1)};
    const unsigned doe{(yoe * 365) + (yoe / 4) - (yoe / 100) + doy};
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    Days = (era * 146097) + static_cast<long>(doe) - 719468;
    return true;
  }

  constexpr static bool DateToJDJulian(long Year, long month, long Day, long& Days) noexcept
  {
    //Validate our parameters
    static_assert(std::numeric_limits<long>::digits >= 20, "This algorithm has not been ported to a 16 bit signed integer");
    if ((month < 1) || (month > 12) || (Day < 1) || (Day > DaysInMonth(month, IsLeap(Year, false))))
      return false;

    if (month <= 2)
      --Year;
    const long era{((Year >= 0) ? Year : (Year - 3)) / 4};
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    const auto yoe{static_cast<unsigned>(Year - (era * 4))};
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    const auto doy{static_cast<unsigned>(((153 * (month + ((month > 2) ? -3 : 9)) + 2) / 5) + Day - 1)};
    const unsigned doe{(yoe * 365) + doy};
#ifdef _MSC_VER
#pragma warning(suppress : 26472)
#endif //#ifdef _MSC_VER
    Days = (era * 1461) + static_cast<long>(doe) - 719470;
    return true;
  }

//Member variables
  double m_dblDays; //The count of days since the epoch
  bool m_bGregorianCalendar; //Is this date in the Gregorian calendar

public:
//Constants
  static constexpr double UNIX_EPOCH_AS_JD = 2440587.5;

//Enums
  enum class DOW
  {
    SUNDAY = 0,
    MONDAY = 1,
    TUESDAY = 2,
    WEDNESDAY = 3,
    THURSDAY = 4,
    FRIDAY = 5,
    SATURDAY = 6
  };

//Non Static methods
  constexpr void SetInGregorianCalendar(bool bGregorianCalendar) noexcept
  {
    m_bGregorianCalendar = bGregorianCalendar;
  }

  constexpr void Set(double JD, bool bGregorianCalendar) noexcept
  {
    m_dblDays = JD - UNIX_EPOCH_AS_JD;
    m_bGregorianCalendar = bGregorianCalendar;
  }

  constexpr void Set(long Year, long Month, double Day, double Hour, double Minute, double Second, bool bGregorianCalendar) noexcept
  {
    if (bGregorianCalendar)
    {
      double tempZ{0};
      const double FDay{std::modf(Day, &tempZ)};
      long Days{0};
      if (DateToJDGregorian(Year, Month, static_cast<long>(Day), Days))
        m_dblDays = Days + (Hour / 24.0) + (Minute / 1440.0) + Second / 86400 + FDay;
      else
        *this = CAADate();
    }
    else
    {
      double tempZ{0};
      const double FDay{std::modf(Day, &tempZ)};
      long Days{0};
      if (DateToJDJulian(Year, Month, static_cast<long>(Day), Days))
        m_dblDays = Days + (Hour / 24.0) + (Minute / 1440.0) + Second / 86400 + FDay;
      else
        *this = CAADate();
    }
    m_bGregorianCalendar = bGregorianCalendar;
  }

  [[nodiscard]] constexpr bool IsValid() const noexcept
  {
    return m_dblDays == m_dblDays;
  }

  constexpr void SetInvalid() noexcept
  {
    m_dblDays = std::numeric_limits<double>::quiet_NaN();
  }

  constexpr void Get(long& Year, long& Month, long& Day, long& Hour, long& Minute, double& Second) const noexcept
  {
    long DaysPart{0};
    double F{0};
    if (m_dblDays >= 0)
    {
      DaysPart = INT(m_dblDays);
      double tempZ{0};
      F = std::modf(m_dblDays, &tempZ);
    }
    else
    {
      DaysPart = INT(m_dblDays);
      double tempZ{0};
      F = std::modf(m_dblDays, &tempZ);
      if (F < 0)
        F = F + 1;
      else
        F = std::fabs(F); //Convert negative zero to positive zero
    }
    if (m_bGregorianCalendar)
      JDToDMYGregorian(DaysPart, Year, Month, Day);
    else
      JDToDMYJulian(DaysPart, Year, Month, Day);
    Hour = static_cast<long>(F * 24);
    Minute = static_cast<long>((F - (Hour / 24.0)) * 1440.0);
    Second = (F - (Hour / 24.0) - (Minute / 1440.0)) * 86400.0;
  }

//Constructors / Destructors
  constexpr CAADate() noexcept : m_dblDays{std::numeric_limits<double>::quiet_NaN()},
                                 m_bGregorianCalendar{false}
  {
  }

  constexpr CAADate(long Year, long Month, double Day, bool bGregorianCalendar) noexcept : CAADate()
  {
    Set(Year, Month, Day, 0, 0, 0, bGregorianCalendar);
  }

  constexpr CAADate(long Year, long Month, double Day, double Hour, double Minute, double Second, bool bGregorianCalendar) noexcept : CAADate()
  {
    Set(Year, Month, Day, Hour, Minute, Second, bGregorianCalendar);
  }

  constexpr CAADate(double JD, bool bGregorianCalendar) noexcept : CAADate()
  {
    Set(JD, bGregorianCalendar);
  }

  constexpr CAADate(const CAADate&) = default;
  constexpr CAADate(CAADate&&) = default;
  ~CAADate() = default;

//Static Methods
  [[nodiscard]] constexpr static bool IsLeap(long Year, bool bGregorianCalendar) noexcept
  {
    if (bGregorianCalendar)
      return (Year % 4 == 0) && (((Year % 100) != 0) || ((Year % 400) == 0));
    else
      return ((Year % 4) == 0) ? true : false;
  }

  constexpr static void DayOfYearToDayAndMonth(long DayOfYear, bool bLeap, long& DayOfMonth, long& Month) noexcept
  {
    long K{bLeap ? 1 : 2};
    Month = INT(9 * (0.0 + K + DayOfYear) / 275.0 + 0.98);
    if (DayOfYear < 32)
      Month = 1;
    DayOfMonth = DayOfYear - INT((275.0 * Month) / 9.0) + (K * INT((Month + 9.0) / 12.0)) + 30;
  }

  [[nodiscard]] constexpr static CAACalendarDate JulianToGregorian(long Year, long Month, long Day) noexcept
  {
    long Days{0};
    if (!DateToJDJulian(Year, Month, Day, Days))
      return CAACalendarDate{};
    CAACalendarDate gregorian;
    JDToDMYGregorian(Days, gregorian.Year, gregorian.Month, gregorian.Day);
    return gregorian;
  }

  [[nodiscard]] constexpr static CAACalendarDate GregorianToJulian(long Year, long Month, long Day) noexcept
  {
    long Days{0};
    if (!DateToJDGregorian(Year, Month, Day, Days))
      return CAACalendarDate{};
    CAACalendarDate julian;
    JDToDMYJulian(Days, julian.Year, julian.Month, julian.Day);
    return julian;
  }

  [[nodiscard]] constexpr static long INT(double value) noexcept
  {
    const auto t{static_cast<long>(value)};
    if (t > value)
      return t - 1;
    else
      return t;
  }

  [[nodiscard]] constexpr static bool AfterPapalReform(long Year, long Month, double Day)
  {
    return ((Year > 1582) || ((Year == 1582) && (Month > 10)) || ((Year == 1582) && (Month == 10) && (Day >= 15)));
  }

  [[nodiscard]] constexpr static bool AfterPapalReform(double JD)
  {
    return (JD >= 2299160.5);
  }

  [[nodiscard]] constexpr static double DayOfYear(double JD, long Year, bool bGregorianCalendar) noexcept
  {
    long Days{0};
    if (bGregorianCalendar)
    {
      if (!DateToJDGregorian(Year, 1, 1, Days))
      {
        assert(false);
        return 0;
      }
    }
    else
    {
      if (!DateToJDJulian(Year, 1, 1, Days))
      {
        assert(false);
        return 0;
      }
    }
    return JD - (Days + UNIX_EPOCH_AS_JD) + 1;
  }

  [[nodiscard]] constexpr static long DaysInCommonMonth(long Month) noexcept
  {
    //Validate our parameters
    assert((Month >= 1) && (Month <= 12));
#ifdef _MSC_VER
    __analysis_assume(Month >= 1 && Month <= 12);
#endif //#ifdef _MSC_VER

    constexpr std::array<unsigned char, 12> g_NonLeapMonths{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
#ifdef _MSC_VER
#pragma warning(suppress : 26425 26446 26472 26482)
#endif //#ifdef _MSC_VER
    return g_NonLeapMonths[static_cast<size_t>(Month) - 1];
  }

  [[nodiscard]] constexpr static long DaysInMonth(long Month, bool bLeap) noexcept
  {
    return (Month != 2) || !bLeap ? DaysInCommonMonth(Month) : 29;
  }

//Non Static methods
  CAADate& operator=(const CAADate&) = default;
  CAADate& operator=(CAADate&&) = default;
  [[nodiscard]] constexpr double Julian() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    return m_dblDays + UNIX_EPOCH_AS_JD;
  };

  constexpr operator double() const noexcept
  {
     return Julian();
  };

  [[nodiscard]] constexpr long Day() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    long Year{0};
    long Month{0};
    long Day{0};
    long Hour{0};
    long Minute{0};
    double Second{0};
    Get(Year, Month, Day, Hour, Minute, Second);
    return Day;
  }

  [[nodiscard]] constexpr long Month() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    long Year{0};
    long Month{0};
    long Day{0};
    long Hour{0};
    long Minute{0};
    double Second{0};
    Get(Year, Month, Day, Hour, Minute, Second);
    return Month;
  }

  [[nodiscard]] constexpr long Year() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    long Year{0};
    long Month{0};
    long Day{0};
    long Hour{0};
    long Minute{0};
    double Second{0};
    Get(Year, Month, Day, Hour, Minute, Second);
    return Year;
  }

  [[nodiscard]] constexpr long Hour() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    long Year{0};
    long Month{0};
    long Day{0};
    long Hour{0};
    long Minute{0};
    double Second{0};
    Get(Year, Month, Day, Hour, Minute, Second);
    return Hour;
  }

  [[nodiscard]] constexpr long Minute() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    long Year{0};
    long Month{0};
    long Day{0};
    long Hour{0};
    long Minute{0};
    double Second{0};
    Get(Year, Month, Day, Hour, Minute, Second);
    return Minute;
  }

  [[nodiscard]] constexpr double Second() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    long Year{0};
    long Month{0};
    long Day{0};
    long Hour{0};
    long Minute{0};
    double Second{0};
    Get(Year, Month, Day, Hour, Minute, Second);
    return Second;
  }

  [[nodiscard]] constexpr DOW DayOfWeek() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    const long z(INT(m_dblDays));
    return static_cast<DOW>(z >= -4 ? (z + 4) % 7 : (z + 5) % 7 + 6);
  }

  [[nodiscard]] constexpr double DayOfYear() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    long Year{0};
    long Month{0};
    long Day{0};
    long Hour{0};
    long Minute{0};
    double Second{0};
    Get(Year, Month, Day, Hour, Minute, Second);
    return DayOfYear(Julian(), Year, m_bGregorianCalendar);
  }

  [[nodiscard]] constexpr long DaysInMonth() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    long Year{0};
    long Month{0};
    long Day{0};
    long Hour{0};
    long Minute{0};
    double Second{0};
    Get(Year, Month, Day, Hour, Minute, Second);
    return DaysInMonth(Month, IsLeap(Year, m_bGregorianCalendar));
  }

  [[nodiscard]] long DaysInYear() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    long Year{0};
    long Month{0};
    long Day{0};
    long Hour{0};
    long Minute{0};
    double Second{0};
    Get(Year, Month, Day, Hour, Minute, Second);
    return IsLeap(Year, m_bGregorianCalendar) ? 366 : 365;
  }

  [[nodiscard]] constexpr bool Leap() const noexcept
  {
    return IsLeap(Year(), m_bGregorianCalendar);
  }

  [[nodiscard]] constexpr bool InGregorianCalendar() const noexcept 
  {
     return m_bGregorianCalendar;
  }

  [[nodiscard]] constexpr double FractionalYear() const noexcept
  {
    //Validate our parameters
    assert(IsValid());

    long Year{0};
    long Month{0};
    long Day{0};
    long Hour{0};
    long Minute{0};
    double Second{0};
    Get(Year, Month, Day, Hour, Minute, Second);
    long DaysInYear{0};
    if (IsLeap(Year, m_bGregorianCalendar))
      DaysInYear = 366;
    else
      DaysInYear = 365;
    const double Fraction{(DayOfYear(Julian(), Year, m_bGregorianCalendar) - 1.0) / DaysInYear};
    return Year + Fraction;
  }
};


#endif //#ifndef __AADATE_H__

USE DWH_Workspace
GO
/****** Object:  StoredProcedure [dbo].[sp_UserEngagementPeriodsWithChurnRetention]    Script Date: 4/3/2024 5:40:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_UserEngagementPeriodsWithChurnRetention] (@BaseDay DATE,@_FeatureType AS INT,@_CardTransactionType AS INT, @_Is_Offline AS INT, @_Is_Abroad AS INT, @_ConditionIdNullity AS TINYINT) AS

DECLARE @_X1 AS INT,@_X2 AS INT,@_Y1 AS INT,@_Y2 AS INT

										IF @_Is_Offline = 1
										BEGIN
											SET @_X1=1
											SET @_Y1=1
										END
										ELSE IF @_Is_Offline=0
										BEGIN
											SET @_X1=0
											SET @_Y1=0
										END
										ELSE IF @_Is_Offline=2
										BEGIN
											SET @_X1=0
											SET @_Y1=1
										END
										ELSE IF @_Is_Offline=-1
										BEGIN
											SET @_X1=-1
											SET @_Y1=-1
										END
										IF @_Is_Abroad = 1
										BEGIN
											SET @_X2=1
											SET @_Y2=1
										END
										ELSE IF @_Is_Abroad=0
										BEGIN
											SET @_X2=0
											SET @_Y2=0
										END
										ELSE IF @_Is_Abroad=2
										BEGIN
											SET @_X2=0
											SET @_Y2=1
										END
										ELSE IF @_Is_Abroad=-1
										BEGIN
											SET @_X2=-1
											SET @_Y2=-1
										END
DROP TABLE IF EXISTS DWH_Workspace.[DWH\skacar].DummyTableForOverallRetention,#TEST,#K1,#K2
DECLARE
--		@BaseDay as Date =	CAST(GETDATE() AS DATE),
		@d       as INT  =  1,
		@y		 as INT  =  0,
		@m		 as INT  =  1
declare @DailySP as Date SET @DailySP = DATEADD(DAY,-@d,@BaseDay)
	    IF YEAR(@BaseDay) != YEAR(DATEADD(DAY,-1,@BaseDay))
		   BEGIN
		   SET @y = @y + 1
		   END
		IF DAY(@BaseDay) = 1
		   BEGIN
		   SET @m = @m + 1
		   END
select
	 MIN(CAST(CreateDate as Date))					FirstDayOfWeek
	,DATEADD(WEEK,-1,MIN(CAST(CreateDate as Date))) FirstDayOfLastWeek
	INTO #TEMP_DummyWeekTable
from
(
	select WeekReAdjustment
	from DWH_Workspace.dbo.DIM_Date with (Nolock)
	where @DailySP = CAST(CreateDate as Date)
) M
LEFT JOIN DWH_Workspace.dbo.DIM_Date D with (Nolock) ON M.WeekReadJustment = D.WeekReAdjustment
		DECLARE @TheDayBeforeDailySP		  AS DATE =					 DATEADD(DAY,-1,@DailySP),
				@Param_R_FirstDayOfWeek		  AS DATE =					 (SELECT FirstDayOfWeek     FROM #TEMP_DummyWeekTable),
				@Param_R_FirstDayOfLastWeek   AS DATE =					 (SELECT FirstDayOfLastWeek FROM #TEMP_DummyWeekTable),
				@Param_IR_Last7Days			  AS DATE =					 DATEADD(DAY,-7  ,@BaseDay),
				@Param_IR_Last14Days		  AS DATE =					 DATEADD(DAY,-14 ,@BaseDay),
				@Param_IR_Last30Days		  AS DATE =					 DATEADD(DAY,-30 ,@BaseDay),
				@Param_IR_Last60Days		  AS DATE =					 DATEADD(DAY,-60 ,@BaseDay),
				@Param_IR_Last90Days		  AS DATE =					 DATEADD(DAY,-90 ,@BaseDay),
				@Param_IR_Last180Days		  AS DATE =					 DATEADD(DAY,-180,@BaseDay),
				@Param_IR_Last360Days		  AS DATE =					 DATEADD(DAY,-360,@BaseDay),
				@Param_IR_Last720Days		  AS DATE =					 DATEADD(DAY,-720,@BaseDay),
				@Param_R_MTDIndicator		  AS DATE =					 DATEADD(DAY,1,EOMonth(dateadd(MONTH,-@m,@BaseDay))),
				@Param_R_2MTDIndicator		  AS DATE = DATEADD(MONTH,-1,DATEADD(DAY,1,EOMonth(dateadd(MONTH,-@m,@BaseDay)))),
			    @Param_R_QTDIndicator		  AS DATE = DATEFROMPARTS(YEAR(Dateadd(day,-@m,@BaseDay)), ((MONTH(dateadd(day,-@m,@BaseDay)) -1)/3)*3+1,1),
			    @Param_R_SemiYTDIndicator	  AS DATE = DATEFROMPARTS(YEAR(Dateadd(day,-@m,@BaseDay)),(((MONTH(dateadd(day,-@m,@BaseDay)))-1)/6)*6+1,1),
			    @Param_R_YTDIndicator		  AS DATE = DATEFROMPARTS(YEAR(Dateadd(day,-@y,@BaseDay)),1,1),
				@Param_R_2YTDIndicator		  AS DATE = DATEFROMPARTS(YEAR(Dateadd(day,-@y,@BaseDay))-1,1,1)
		DROP TABLE IF EXISTS #TEMP_DummyWeekTable

		SELECT
			 1 DummyForJoining
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_R_FirstDayOfWeek		THEN CustomerKey END) UUWTD
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_R_FirstDayOfLastWeek  THEN CustomerKey END) UU2WTD
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_R_MTDIndicator		THEN CustomerKey END) UUMTD
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_R_2MTDIndicator		THEN CustomerKey END) UU2MTD
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_R_QTDIndicator		THEN CustomerKey END) UUQTD
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_R_SemiYTDIndicator	THEN CustomerKey END) UUSemiYTD
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_R_YTDIndicator		THEN CustomerKey END) UUYTD
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_R_2YTDIndicator		THEN CustomerKey END) UU2YTD
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @DailySP						THEN CustomerKey END) UU_CurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @TheDayBeforeDailySP			THEN CustomerKey END) UU_TheDayBeforeCurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last7Days			THEN CustomerKey END) UU_Last7Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last14Days			THEN CustomerKey END) UU_Last14Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last30Days			THEN CustomerKey END) UU_Last30Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last60Days			THEN CustomerKey END) UU_Last60Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last90Days			THEN CustomerKey END) UU_Last90Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last180Days		THEN CustomerKey END) UU_Last180Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last360Days		THEN CustomerKey END) UU_Last360Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last720Days		THEN CustomerKey END) UU_Last720Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @TheDayBeforeDailySP	 AND CreateDateTime < @DailySP				THEN CustomerKey END)	UU_TheDayBeforeCurrentDate_CurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last7Days	 AND CreateDateTime < @DailySP				THEN CustomerKey END)	UU_Last7Days_CurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last14Days	 AND CreateDateTime < @DailySP				THEN CustomerKey END)	UU_Last14Days_CurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last30Days	 AND CreateDateTime < @DailySP				THEN CustomerKey END)	UU_Last30Days_CurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last60Days	 AND CreateDateTime < @DailySP				THEN CustomerKey END)	UU_Last60Days_CurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last90Days	 AND CreateDateTime < @DailySP				THEN CustomerKey END)	UU_Last90Days_CurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last180Days AND CreateDateTime < @DailySP				THEN CustomerKey END)	UU_Last180Days_CurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last360Days AND CreateDateTime < @DailySP				THEN CustomerKey END)	UU_Last360Days_CurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last720Days AND CreateDateTime < @DailySP				THEN CustomerKey END)	UU_Last720Days_CurrentDate
---
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last7Days	 AND CreateDateTime < @TheDayBeforeDailySP	THEN CustomerKey END)	UU_Last7Days_TheDayBeforeCurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last14Days	 AND CreateDateTime < @TheDayBeforeDailySP	THEN CustomerKey END)	UU_Last14Days_TheDayBeforeCurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last30Days	 AND CreateDateTime < @TheDayBeforeDailySP	THEN CustomerKey END)	UU_Last30Days_TheDayBeforeCurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last60Days	 AND CreateDateTime < @TheDayBeforeDailySP	THEN CustomerKey END)	UU_Last60Days_TheDayBeforeCurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last90Days	 AND CreateDateTime < @TheDayBeforeDailySP	THEN CustomerKey END)	UU_Last90Days_TheDayBeforeCurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last180Days AND CreateDateTime < @TheDayBeforeDailySP	THEN CustomerKey END)	UU_Last180Days_TheDayBeforeCurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last360Days AND CreateDateTime < @TheDayBeforeDailySP	THEN CustomerKey END)	UU_Last360Days_TheDayBeforeCurrentDate
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last720Days AND CreateDateTime < @TheDayBeforeDailySP	THEN CustomerKey END)	UU_Last720Days_TheDayBeforeCurrentDate
---
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last14Days	 AND CreateDateTime < @Param_IR_Last7Days	THEN CustomerKey END)	UU_Last14Days_Last7Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last30Days	 AND CreateDateTime < @Param_IR_Last7Days	THEN CustomerKey END)	UU_Last30Days_Last7Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last60Days	 AND CreateDateTime < @Param_IR_Last7Days	THEN CustomerKey END)	UU_Last60Days_Last7Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last90Days	 AND CreateDateTime < @Param_IR_Last7Days	THEN CustomerKey END)	UU_Last90Days_Last7Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last180Days AND CreateDateTime < @Param_IR_Last7Days	THEN CustomerKey END)	UU_Last180Days_Last7Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last360Days AND CreateDateTime < @Param_IR_Last7Days	THEN CustomerKey END)	UU_Last360Days_Last7Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last720Days AND CreateDateTime < @Param_IR_Last7Days	THEN CustomerKey END)	UU_Last720Days_Last7Days
---
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last30Days	 AND CreateDateTime < @Param_IR_Last14Days	THEN CustomerKey END)	UU_Last30Days_Last14Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last60Days	 AND CreateDateTime < @Param_IR_Last14Days	THEN CustomerKey END)	UU_Last60Days_Last14Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last90Days	 AND CreateDateTime < @Param_IR_Last14Days	THEN CustomerKey END)	UU_Last90Days_Last14Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last180Days AND CreateDateTime < @Param_IR_Last14Days	THEN CustomerKey END)	UU_Last180Days_Last14Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last360Days AND CreateDateTime < @Param_IR_Last14Days	THEN CustomerKey END)	UU_Last360Days_Last14Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last720Days AND CreateDateTime < @Param_IR_Last14Days	THEN CustomerKey END)	UU_Last720Days_Last14Days
---
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last60Days	 AND CreateDateTime < @Param_IR_Last30Days	THEN CustomerKey END)	UU_Last60Days_Last30Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last90Days	 AND CreateDateTime < @Param_IR_Last30Days	THEN CustomerKey END)	UU_Last90Days_Last30Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last180Days AND CreateDateTime < @Param_IR_Last30Days	THEN CustomerKey END)	UU_Last180Days_Last30Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last360Days AND CreateDateTime < @Param_IR_Last30Days	THEN CustomerKey END)	UU_Last360Days_Last30Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last720Days AND CreateDateTime < @Param_IR_Last30Days	THEN CustomerKey END)	UU_Last720Days_Last30Days
---
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last90Days	 AND CreateDateTime < @Param_IR_Last60Days	THEN CustomerKey END)	UU_Last90Days_Last60Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last180Days AND CreateDateTime < @Param_IR_Last60Days	THEN CustomerKey END)	UU_Last180Days_Last60Days

			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last360Days AND CreateDateTime < @Param_IR_Last60Days	THEN CustomerKey END)	UU_Last360Days_Last60Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last720Days AND CreateDateTime < @Param_IR_Last60Days	THEN CustomerKey END)	UU_Last720Days_Last60Days
---

			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last180Days AND CreateDateTime < @Param_IR_Last90Days	THEN CustomerKey END)	UU_Last180Days_Last90Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last360Days AND CreateDateTime < @Param_IR_Last90Days	THEN CustomerKey END)	UU_Last360Days_Last90Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last720Days AND CreateDateTime < @Param_IR_Last90Days	THEN CustomerKey END)	UU_Last720Days_Last90Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last720Days AND CreateDateTime < @Param_IR_Last180Days	THEN CustomerKey END)	UU_Last720Days_Last180Days
			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last720Days AND CreateDateTime < @Param_IR_Last360Days	THEN CustomerKey END)	UU_Last720Days_Last360Days


			,COUNT(DISTINCT CASE WHEN CreateDateTime >= @Param_IR_Last360Days AND CreateDateTime < @Param_IR_Last180Days	THEN CustomerKey END)	UU_Last360Days_Last180Days
		INTO #K1
		FROM DWH_Workspace.dbo.FACT_Transactions With (Nolock)
		WHERE	CreateDateTime >= DATEADD(day,-12,@Param_IR_Last720Days) AND CreateDateTime < @BaseDay
			AND IsCancellation = 0 AND OperationEmployeeKey IS NULL AND Currency = 0
			AND FeatureType = @_FeatureType AND ISNULL(CardTransactionType,@_CardTransactionType)=@_CardTransactionType
			AND (ISNULL(cast(Is_Offline as int),@_X1)=@_X1 OR ISNULL(cast(Is_Offline as int),@_Y1)=@_Y1) AND (ISNULL(cast(Is_Abroad as int),@_X2)=@_X2 OR ISNULL(cast(Is_Abroad as int),@_Y2)=@_Y2)
			AND (
					(@_ConditionIdNullity = 1 AND ConditionId IS NOT NULL) OR (@_ConditionIdNullity = 0 AND ConditionId IS NULL) OR (@_ConditionIdNullity = 2)
				)

		--DELETE FROM DWH_Workspace.[DWH\skacar].FACT_BI_UserEngagementPeriodsWithChurnRetention WHERE [Date] = @DailySP AND FeatureType = @_FeatureType AND Is_Offline = CASE WHEN @_Is_Offline=1 THEN 1 WHEN @_Is_Offline=0 THEN 0 ELSE NULL END
		--																																			 AND Is_Abroad  = CASE WHEN @_Is_Abroad =1 THEN 1 WHEN @_Is_Abroad =0 THEN 0 ELSE NULL END
		--																																			 AND CardTransactionType = CASE WHEN @_CardTransactionType = -1 THEN NULL ELSE @_CardTransactionType END
		--																																			 			AND CASE WHEN ConditionIdIsNull IS	   NULL								 THEN 0
		--																																								 WHEN ConditionIdIsNull IS NOT NULL								 THEN 1
		--																																								 WHEN ConditionIdIsNull IS NOT NULL OR ConditionIdIsNull IS NULL THEN NULL
		--																																							END = @_ConditionIdNullity													 
		;
		WITH UserPeriods_ByFirstTransactions AS
		(
		 SELECT Userkey,MIN(MinCreateDateTime) MinCreateDateTime
		 FROM
			(
				SELECT CustomerKey,MIN(CreateDateTime) MinCreateDateTime									
				FROM DWH_Workspace.dbo.FACT_Transactions	   with (Nolock)
				WHERE FeatureType = @_FeatureType AND  ISNULL(CardTransactionType,@_CardTransactionType)=@_CardTransactionType AND  (ISNULL(cast(Is_Offline as int),@_X1)=@_X1 OR ISNULL(cast(Is_Offline as int),@_Y1)=@_Y1) AND (ISNULL(cast(Is_Abroad as int),@_X2)=@_X2 OR ISNULL(cast(Is_Abroad as int),@_Y2)=@_Y2) AND Currency = 0 AND IsCancellation=0 AND OperationEmployeeKey IS NULL
					  AND ((@_ConditionIdNullity = 1 AND ConditionId IS NOT NULL) OR (@_ConditionIdNullity = 0 AND ConditionId IS NULL) OR (@_ConditionIdNullity = 2))
				GROUP BY CustomerKey 
				UNION ALL
				SELECT CustomerKey,MIN(CreateDateTime) MinCreateDateTime
				FROM Transactions2020Before.dbo.FACT_Transactions	with (Nolock)
				WHERE FeatureType = @_FeatureType AND ISNULL(CardTransactionType,@_CardTransactionType)=@_CardTransactionType AND (ISNULL(cast(Is_Offline as int),@_X1)=@_X1 OR ISNULL(cast(Is_Offline as int),@_Y1)=@_Y1) AND (ISNULL(cast(Is_Abroad as int),@_X2)=@_X2 OR ISNULL(cast(Is_Abroad as int),@_Y2)=@_Y2) AND Currency = 0 AND IsCancellation=0 AND OperationEmployeeKey IS NULL
					 AND ((@_ConditionIdNullity = 1 AND ConditionId IS NOT NULL) OR (@_ConditionIdNullity = 0 AND ConditionId IS NULL) OR (@_ConditionIdNullity = 2))
				GROUP BY CustomerKey
			) FirstTransactionDateTime
		 GROUP BY CustomerKey
		)
		SELECT 1 DummyForJoining
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_2YTDIndicator	  THEN CustomerKey END)	UU_FirstTx2YTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_YTDIndicator		  THEN CustomerKey END)	UU_FirstTxYTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_SemiYTDIndicator   THEN CustomerKey END)	UU_FirstTxSemiYTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_QTDIndicator		  THEN CustomerKey END)	UU_FirstTxQTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_2MTDIndicator	  THEN CustomerKey END)	UU_FirstTx2MTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_MTDIndicator		  THEN CustomerKey END)	UU_FirstTxMTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_FirstDayOfLastWeek THEN CustomerKey END)	UU_FirstTx2WTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_FirstDayOfWeek	  THEN CustomerKey END)	UU_FirstTxWTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last720Days		  THEN CustomerKey END)	UU_FirstTxInLast720Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last360Days		  THEN CustomerKey END)	UU_FirstTxInLast360Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last180Days		  THEN CustomerKey END)	UU_FirstTxInLast180Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last90Days		  THEN CustomerKey END)	UU_FirstTxInLast90Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last60Days		  THEN CustomerKey END)	UU_FirstTxInLast60Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last30Days		  THEN CustomerKey END)	UU_FirstTxInLast30Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last14Days		  THEN CustomerKey END)	UU_FirstTxInLast14Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last7Days		  THEN CustomerKey END)	UU_FirstTxInLast7Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @DailySP					  THEN CustomerKey END) UU_FirstTxCurrentDate
			 ,COUNT(CASE WHEN MinCreateDateTime >= @TheDayBeforeDailySP		  THEN CustomerKey END) UU_FirstTxTheDayBeforeCurrentDate
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_2YTDIndicator	  AND U.CreateDateTime >= @Param_R_2YTDIndicator		  THEN CustomerKey END)	UU_FirstTx2YTDRegistered2YTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_YTDIndicator		  AND U.CreateDateTime >= @Param_R_YTDIndicator		  THEN CustomerKey END)	UU_FirstTxYTDRegisteredYTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_SemiYTDIndicator   AND U.CreateDateTime >= @Param_R_SemiYTDIndicator    THEN CustomerKey END)	UU_FirstTxSemiYTDRegisteredSemiYTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_QTDIndicator		  AND U.CreateDateTime >= @Param_R_QTDIndicator		  THEN CustomerKey END)	UU_FirstTxQTDRegisteredQTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_2MTDIndicator	  AND U.CreateDateTime >= @Param_R_2MTDIndicator		  THEN CustomerKey END)	UU_FirstTx2MTDRegistered2MTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_MTDIndicator		  AND U.CreateDateTime >= @Param_R_MTDIndicator		  THEN CustomerKey END)	UU_FirstTxMTDRegisteredMTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_FirstDayOfLastWeek AND U.CreateDateTime >= @Param_R_FirstDayOfLastWeek  THEN CustomerKey END)	UU_FirstTx2WTDRegistered2WTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_R_FirstDayOfWeek	  AND U.CreateDateTime >= @Param_R_FirstDayOfWeek	  THEN CustomerKey END)	UU_FirstTxWTDRegisteredWTD
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last720Days		  AND U.CreateDateTime >= @Param_IR_Last720Days		  THEN CustomerKey END)	UU_FirstTxInLast720DaysRegistered720Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last360Days		  AND U.CreateDateTime >= @Param_IR_Last360Days		  THEN CustomerKey END)	UU_FirstTxInLast360DaysRegistered360Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last180Days		  AND U.CreateDateTime >= @Param_IR_Last180Days		  THEN CustomerKey END)	UU_FirstTxInLast180DaysRegistered180Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last90Days		  AND U.CreateDateTime >= @Param_IR_Last90Days		  THEN CustomerKey END)	UU_FirstTxInLast90DaysRegistered90Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last60Days		  AND U.CreateDateTime >= @Param_IR_Last60Days		  THEN CustomerKey END)	UU_FirstTxInLast60DaysRegistered60Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last30Days		  AND U.CreateDateTime >= @Param_IR_Last30Days		  THEN CustomerKey END)	UU_FirstTxInLast30DaysRegistered30Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last14Days		  AND U.CreateDateTime >= @Param_IR_Last14Days		  THEN CustomerKey END)	UU_FirstTxInLast14DaysRegistered14Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @Param_IR_Last7Days		  AND U.CreateDateTime >= @Param_IR_Last7Days		  THEN CustomerKey END)	UU_FirstTxInLast7DaysRegistered7Days
			 ,COUNT(CASE WHEN MinCreateDateTime >= @TheDayBeforeDailySP		  AND U.CreateDateTime >= @TheDayBeforeDailySP		  THEN CustomerKey END) UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate
			 ,COUNT(CASE WHEN MinCreateDateTime >= @DailySP					  AND U.CreateDateTime >= @DailySP					  THEN CustomerKey END) UU_FirstTxCurrentDateRegisteredCurrentDate

		INTO #K2
		FROM  DWH_Workspace.dbo.DIM_Users U with (NOLOCK)
		LEFT JOIN UserPeriods_ByFirstTransactions FT ON FT.CustomerKey = U.User_Key
		WHERE MinCreateDateTime >=  DATEADD(day,-12,@Param_IR_Last720Days) AND MinCreateDateTime < @BaseDay
		;
		DELETE FROM DWH_ManipulatedTables.DBO.FACT_BI_UserEngagementPeriodsWithChurnRetention WHERE [Date] = @DailySP AND   @_FeatureType = 2 AND @_CardTransactionType=1 AND @_Is_Offline=2 AND @_Is_Abroad=2 AND @_ConditionIdNullity=2
		;
		WITH DummyForStructure AS
		(
			SELECT 1 DummyForJoining FROM #K1
		),RawData_CTE AS
		(
		SELECT
			 UUWTD
			,UU2WTD
			,UUMTD
			,UU2MTD
			,UUQTD
			,UUSemiYTD
			,UUYTD
			,UU2YTD
			,UU_CurrentDate
			,UU_TheDayBeforeCurrentDate
			,UU_Last7Days
			,UU_Last14Days
			,UU_Last30Days
			,UU_Last60Days
			,UU_Last90Days
			,UU_Last180Days
			,UU_Last360Days
			,UU_Last720Days
			,UU_FirstTx2YTD
			,UU_FirstTxYTD
			,UU_FirstTxSemiYTD
			,UU_FirstTxQTD
			,UU_FirstTx2MTD
			,UU_FirstTxMTD
			,UU_FirstTx2WTD
			,UU_FirstTxWTD
			,UU_FirstTxCurrentDate
			,UU_FirstTxTheDayBeforeCurrentDate
			,UU_FirstTxInLast720Days
			,UU_FirstTxInLast360Days
			,UU_FirstTxInLast180Days
			,UU_FirstTxInLast90Days
			,UU_FirstTxInLast60Days
			,UU_FirstTxInLast30Days
			,UU_FirstTxInLast14Days
			,UU_FirstTxInLast7Days

			,UU_FirstTx2YTDRegistered2YTD
			,UU_FirstTxYTDRegisteredYTD
			,UU_FirstTxSemiYTDRegisteredSemiYTD
			,UU_FirstTxQTDRegisteredQTD
			,UU_FirstTx2MTDRegistered2MTD
			,UU_FirstTxMTDRegisteredMTD
			,UU_FirstTx2WTDRegistered2WTD
			,UU_FirstTxWTDRegisteredWTD
			,UU_FirstTxInLast720DaysRegistered720Days
			,UU_FirstTxInLast360DaysRegistered360Days
			,UU_FirstTxInLast180DaysRegistered180Days
			,UU_FirstTxInLast90DaysRegistered90Days
			,UU_FirstTxInLast60DaysRegistered60Days
			,UU_FirstTxInLast30DaysRegistered30Days
			,UU_FirstTxInLast14DaysRegistered14Days
			,UU_FirstTxInLast7DaysRegistered7Days
			,UU_FirstTxCurrentDateRegisteredCurrentDate
			,UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate

			,(COALESCE((UU_FirstTx2YTDRegistered2YTD			  )*1.0/(NULLIF(UU_FirstTx2YTD					  , 0)), 0)) RateOf_UU_FirstTx2YTDRegistered2YTD_Over_UU_FirstTx2YTD
			,(COALESCE((UU_FirstTxYTDRegisteredYTD				  )*1.0/(NULLIF(UU_FirstTxYTD					  , 0)), 0)) RateOf_UU_FirstTxYTDRegisteredYTD_Over_UU_FirstTxYTD
			,(COALESCE((UU_FirstTxSemiYTDRegisteredSemiYTD		  )*1.0/(NULLIF(UU_FirstTxSemiYTD				  , 0)), 0)) RateOf_UU_FirstTxSemiYTDRegisteredSemiYTD_Over_UU_FirstTxSemiYTD
			,(COALESCE((UU_FirstTxQTDRegisteredQTD				  )*1.0/(NULLIF(UU_FirstTxQTD					  , 0)), 0)) RateOf_UU_FirstTxQTDRegisteredQTD_Over_UU_FirstTxQTD
			,(COALESCE((UU_FirstTx2MTDRegistered2MTD			  )*1.0/(NULLIF(UU_FirstTx2MTD					  , 0)), 0)) RateOf_UU_FirstTx2MTDRegistered2MTD_Over_UU_FirstTx2MTD
			,(COALESCE((UU_FirstTxMTDRegisteredMTD				  )*1.0/(NULLIF(UU_FirstTxMTD					  , 0)), 0)) RateOf_UU_FirstTxMTDRegisteredMTD_Over_UU_FirstTxMTD
			,(COALESCE((UU_FirstTx2WTDRegistered2WTD			  )*1.0/(NULLIF(UU_FirstTx2WTD					  , 0)), 0)) RateOf_UU_FirstTx2WTDRegistered2WTD_Over_UU_FirstTx2WTD
			,(COALESCE((UU_FirstTxWTDRegisteredWTD				  )*1.0/(NULLIF(UU_FirstTxWTD					  , 0)), 0)) RateOf_UU_FirstTxWTDRegisteredWTD_Over_UU_FirstTxWTD
			,(COALESCE((UU_FirstTxInLast720DaysRegistered720Days  )*1.0/(NULLIF(UU_FirstTxInLast720Days			  , 0)), 0)) RateOf_UU_FirstTxInLast720DaysRegistered720Days_Over_UU_FirstTxInLast720Days
			,(COALESCE((UU_FirstTxInLast360DaysRegistered360Days  )*1.0/(NULLIF(UU_FirstTxInLast360Days			  , 0)), 0)) RateOf_UU_FirstTxInLast360DaysRegistered360Days_Over_UU_FirstTxInLast360Days
			,(COALESCE((UU_FirstTxInLast180DaysRegistered180Days  )*1.0/(NULLIF(UU_FirstTxInLast180Days			  , 0)), 0)) RateOf_UU_FirstTxInLast180DaysRegistered180Days_Over_UU_FirstTxInLast180Days
			,(COALESCE((UU_FirstTxInLast90DaysRegistered90Days	  )*1.0/(NULLIF(UU_FirstTxInLast90Days			  , 0)), 0)) RateOf_UU_FirstTxInLast90DaysRegistered90Days_Over_UU_FirstTxInLast90Days
			,(COALESCE((UU_FirstTxInLast60DaysRegistered60Days	  )*1.0/(NULLIF(UU_FirstTxInLast60Days			  , 0)), 0)) RateOf_UU_FirstTxInLast60DaysRegistered60Days_Over_UU_FirstTxInLast60Days
			,(COALESCE((UU_FirstTxInLast30DaysRegistered30Days	  )*1.0/(NULLIF(UU_FirstTxInLast30Days			  , 0)), 0)) RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_FirstTxInLast30Days
			,(COALESCE((UU_FirstTxInLast14DaysRegistered14Days	  )*1.0/(NULLIF(UU_FirstTxInLast14Days			  , 0)), 0)) RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_FirstTxInLast14Days
			,(COALESCE((UU_FirstTxInLast7DaysRegistered7Days	  )*1.0/(NULLIF(UU_FirstTxInLast7Days			  , 0)), 0)) RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_FirstTxInLast7Days
			,(COALESCE((UU_FirstTxCurrentDateRegisteredCurrentDate)*1.0/(NULLIF(UU_FirstTxCurrentDate			  , 0)), 0)) RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_FirstTxCurrentDate
			,(COALESCE((UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate)*1.0/(NULLIF(UU_FirstTxTheDayBeforeCurrentDate , 0)), 0)) RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate



			,(COALESCE((UU_FirstTx2YTD		   )*1.0/(NULLIF(UU2YTD			, 0)), 0)) RateOf_UU_FirstTx2YTD_Over_UU2YTD	
			,(COALESCE((UU_FirstTxYTD		   )*1.0/(NULLIF(UUYTD			, 0)), 0)) RateOf_UU_FirstTxYTD_Over_UUYTD
			,(COALESCE((UU_FirstTxSemiYTD	   )*1.0/(NULLIF(UUSemiYTD		, 0)), 0)) RateOf_UU_FirstTxSemiYTD_Over_UUSemiYTD
			,(COALESCE((UU_FirstTxQTD		   )*1.0/(NULLIF(UUQTD			, 0)), 0)) RateOf_UU_FirstTxQTD_Over_UUQTD
			,(COALESCE((UU_FirstTx2MTD		   )*1.0/(NULLIF(UU2MTD			, 0)), 0)) RateOf_UU_FirstTx2MTD_Over_UU2MTD
			,(COALESCE((UU_FirstTxMTD		   )*1.0/(NULLIF(UUMTD			, 0)), 0)) RateOf_UU_FirstTxMTD_Over_UUMTD
			,(COALESCE((UU_FirstTx2WTD		   )*1.0/(NULLIF(UU2WTD			, 0)), 0)) RateOf_UU_FirstTx2WTD_Over_UU2WTD
			,(COALESCE((UU_FirstTxWTD		   )*1.0/(NULLIF(UUWTD			, 0)), 0)) RateOf_UU_FirstTxWTD_Over_UUWTD
			,(COALESCE((UU_FirstTxCurrentDate  )*1.0/(NULLIF(UU_CurrentDate	, 0)), 0)) RateOf_UU_FirstTxCurrentDate_Over_UU_CurrentDate
			,(COALESCE((UU_FirstTxCurrentDate  )*1.0/(NULLIF(UU_CurrentDate	, 0)), 0)) RateOf_UU_FirstTxTheDayBeforeCurrentDate_Over_UU_TheDayBeforeCurrentDate
			,(COALESCE((UU_FirstTxInLast720Days)*1.0/(NULLIF(UU_Last720Days	, 0)), 0)) RateOf_UU_FirstTxInLast720Days_Over_UU_Last720Days
			,(COALESCE((UU_FirstTxInLast360Days)*1.0/(NULLIF(UU_Last360Days	, 0)), 0)) RateOf_UU_FirstTxInLast360Days_Over_UU_Last360Days
			,(COALESCE((UU_FirstTxInLast180Days)*1.0/(NULLIF(UU_Last180Days	, 0)), 0)) RateOf_UU_FirstTxInLast180Days_Over_UU_Last180Days
			,(COALESCE((UU_FirstTxInLast90Days )*1.0/(NULLIF(UU_Last90Days	, 0)), 0)) RateOf_UU_FirstTxInLast90Days_Over_UU_Last90Days
			,(COALESCE((UU_FirstTxInLast60Days )*1.0/(NULLIF(UU_Last60Days	, 0)), 0)) RateOf_UU_FirstTxInLast60Days_Over_UU_Last60Days
			,(COALESCE((UU_FirstTxInLast30Days )*1.0/(NULLIF(UU_Last30Days	, 0)), 0)) RateOf_UU_FirstTxInLast30Days_Over_UU_Last30Days
			,(COALESCE((UU_FirstTxInLast14Days )*1.0/(NULLIF(UU_Last14Days	, 0)), 0)) RateOf_UU_FirstTxInLast14Days_Over_UU_Last14Days
			,(COALESCE((UU_FirstTxInLast7Days  )*1.0/(NULLIF(UU_Last7Days	, 0)), 0)) RateOf_UU_FirstTxInLast7Days_Over_UU_Last7Days

			,(COALESCE((UU_FirstTx2YTDRegistered2YTD			  )*1.0 / (NULLIF(UU2YTD		, 0)), 0)) RateOf_UU_FirstTx2YTDRegistered2YTD_Over_UU2YTD			
			,(COALESCE((UU_FirstTxYTDRegisteredYTD				  )*1.0 / (NULLIF(UUYTD			, 0)), 0)) RateOf_UU_FirstTxYTDRegisteredYTD_Over_UUYTD			
			,(COALESCE((UU_FirstTxSemiYTDRegisteredSemiYTD		  )*1.0 / (NULLIF(UUSemiYTD		, 0)), 0)) RateOf_UU_FirstTxSemiYTDRegisteredSemiYTD_Over_UUSemiYTD		
			,(COALESCE((UU_FirstTxQTDRegisteredQTD				  )*1.0 / (NULLIF(UUQTD			, 0)), 0)) RateOf_UU_FirstTxQTDRegisteredQTD_Over_UUQTD			
			,(COALESCE((UU_FirstTx2MTDRegistered2MTD			  )*1.0 / (NULLIF(UU2MTD		, 0)), 0)) RateOf_UU_FirstTx2MTDRegistered2MTD_Over_UU2MTD			
			,(COALESCE((UU_FirstTxMTDRegisteredMTD				  )*1.0 / (NULLIF(UUMTD			, 0)), 0)) RateOf_UU_FirstTxMTDRegisteredMTD_Over_UUMTD			
			,(COALESCE((UU_FirstTx2WTDRegistered2WTD			  )*1.0 / (NULLIF(UU2WTD		, 0)), 0)) RateOf_UU_FirstTx2WTDRegistered2WTD_Over_UU2WTD			
			,(COALESCE((UU_FirstTxWTDRegisteredWTD				  )*1.0 / (NULLIF(UUWTD			, 0)), 0)) RateOf_UU_FirstTxWTDRegisteredWTD_Over_UUWTD			
			,(COALESCE((UU_FirstTxInLast720DaysRegistered720Days  )*1.0 / (NULLIF(UU_Last720Days, 0)), 0)) RateOf_UU_FirstTxInLast720DaysRegistered720Days_Over_UU_Last720Days	
			,(COALESCE((UU_FirstTxInLast360DaysRegistered360Days  )*1.0 / (NULLIF(UU_Last360Days, 0)), 0)) RateOf_UU_FirstTxInLast360DaysRegistered360Days_Over_UU_Last360Days	
			,(COALESCE((UU_FirstTxInLast180DaysRegistered180Days  )*1.0 / (NULLIF(UU_Last180Days, 0)), 0)) RateOf_UU_FirstTxInLast180DaysRegistered180Days_Over_UU_Last180Days	
			,(COALESCE((UU_FirstTxInLast90DaysRegistered90Days	  )*1.0 / (NULLIF(UU_Last90Days	, 0)), 0)) RateOf_UU_FirstTxInLast90DaysRegistered90Days_Over_UU_Last90Days	
			,(COALESCE((UU_FirstTxInLast60DaysRegistered60Days	  )*1.0 / (NULLIF(UU_Last60Days	, 0)), 0)) RateOf_UU_FirstTxInLast60DaysRegistered60Days_Over_UU_Last60Days	
			,(COALESCE((UU_FirstTxInLast30DaysRegistered30Days	  )*1.0 / (NULLIF(UU_Last30Days	, 0)), 0)) RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_Last30Days	
			,(COALESCE((UU_FirstTxInLast14DaysRegistered14Days	  )*1.0 / (NULLIF(UU_Last14Days	, 0)), 0)) RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_Last14Days	
			,(COALESCE((UU_FirstTxInLast7DaysRegistered7Days	  )*1.0 / (NULLIF(UU_Last7Days	, 0)), 0)) RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_Last7Days	
			,(COALESCE((UU_FirstTxCurrentDateRegisteredCurrentDate)*1.0 / (NULLIF(UU_CurrentDate, 0)), 0)) RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_CurrentDate

			,(COALESCE((UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate)*1.0 / (NULLIF(UU_FirstTxTheDayBeforeCurrentDate, 0)), 0)) RateOf_UU_FirstTxCurrentDateRegisteredTheDayBeforeCurrentDate_Over_UU_TheDayBeforeCurrentDate
						/*CurrentDate vs TheDayBeforeCurrentDate*/
						,UU_TheDayBeforeCurrentDate			 - UU_TheDayBeforeCurrentDate_CurrentDate					UU_NewContributer_CurrentDate_To_TheDayBeforeCurrentDate
						,UU_TheDayBeforeCurrentDate_CurrentDate + UU_CurrentDate -			UU_TheDayBeforeCurrentDate	UU_Retained_CurrentDate_Through_TheDayBeforeCurrentDate
						,UU_TheDayBeforeCurrentDate			 - UU_CurrentDate								UU_Churned_CurrentDate_Through_TheDayBeforeCurrentDate
						,	 (COALESCE((UU_TheDayBeforeCurrentDate_CurrentDate + UU_CurrentDate - UU_TheDayBeforeCurrentDate)*1.0 / (NULLIF(UU_TheDayBeforeCurrentDate_CurrentDate, 0)), 0)) RetentionRate_CurrentDate_Through_TheDayBeforeCurrentDate
						,1.0-(COALESCE((UU_TheDayBeforeCurrentDate_CurrentDate + UU_CurrentDate - UU_TheDayBeforeCurrentDate)*1.0 / (NULLIF(UU_TheDayBeforeCurrentDate_CurrentDate, 0)), 0)) ChurnRate_CurrentDate_Through_TheDayBeforeCurrentDate

						/*CurrentDate vs Last7Days*/
						,UU_Last7Days			 - UU_Last7Days_CurrentDate					UU_NewContributer_CurrentDate_To_7Days
						,UU_Last7Days_CurrentDate + UU_CurrentDate -			UU_Last7Days	UU_Retained_CurrentDate_Through_7Days
						,UU_Last7Days			 - UU_CurrentDate								UU_Churned_CurrentDate_Through_7Days
						,	 (COALESCE((UU_Last7Days_CurrentDate + UU_CurrentDate - UU_Last7Days)*1.0 / (NULLIF(UU_Last7Days_CurrentDate, 0)), 0)) RetentionRate_CurrentDate_Through_7Days
						,1.0-(COALESCE((UU_Last7Days_CurrentDate + UU_CurrentDate - UU_Last7Days)*1.0 / (NULLIF(UU_Last7Days_CurrentDate, 0)), 0)) ChurnRate_CurrentDate_Through_7Days

						/*CurrentDate vs Last14Days*/
						,UU_Last14Days			 - UU_Last14Days_CurrentDate					UU_NewContributer_CurrentDate_To_14Days
						,UU_Last14Days_CurrentDate + UU_CurrentDate -			UU_Last14Days	UU_Retained_CurrentDate_Through_14Days
						,UU_Last14Days			 - UU_CurrentDate								UU_Churned_CurrentDate_Through_14Days
						,	 (COALESCE((UU_Last14Days_CurrentDate + UU_CurrentDate - UU_Last14Days)*1.0 / (NULLIF(UU_Last14Days_CurrentDate, 0)), 0)) RetentionRate_CurrentDate_Through_14Days
						,1.0-(COALESCE((UU_Last14Days_CurrentDate + UU_CurrentDate - UU_Last14Days)*1.0 / (NULLIF(UU_Last14Days_CurrentDate, 0)), 0)) ChurnRate_CurrentDate_Through_14Days

						/*CurrentDate vs Last30Days*/
						,UU_Last30Days			 - UU_Last30Days_CurrentDate					UU_NewContributer_CurrentDate_To_30Days
						,UU_Last30Days_CurrentDate + UU_CurrentDate -			UU_Last30Days	UU_Retained_CurrentDate_Through_30Days
						,UU_Last30Days			 - UU_CurrentDate								UU_Churned_CurrentDate_Through_30Days
						,	 (COALESCE((UU_Last30Days_CurrentDate + UU_CurrentDate - UU_Last30Days)*1.0 / (NULLIF(UU_Last30Days_CurrentDate, 0)), 0)) RetentionRate_CurrentDate_Through_30Days
						,1.0-(COALESCE((UU_Last30Days_CurrentDate + UU_CurrentDate - UU_Last30Days)*1.0 / (NULLIF(UU_Last30Days_CurrentDate, 0)), 0)) ChurnRate_CurrentDate_Through_30Days

						/*CurrentDate vs Last60Days*/
						,UU_Last60Days			  - UU_Last60Days_CurrentDate				UU_NewContributer_CurrentDate_To_60Days
						,UU_Last60Days_CurrentDate + UU_CurrentDate -			UU_Last60Days	UU_Retained_CurrentDate_Through_60Days
						,UU_Last60Days			  - UU_CurrentDate							UU_Churned_CurrentDate_Through_60Days
						,	 (COALESCE((UU_Last60Days_CurrentDate + UU_CurrentDate - UU_Last60Days)*1.0 / (NULLIF(UU_Last60Days_CurrentDate, 0)), 0))  RetentionRate_CurrentDate_Through_60Days
						,1.0-(COALESCE((UU_Last60Days_CurrentDate + UU_CurrentDate - UU_Last60Days)*1.0 / (NULLIF(UU_Last60Days_CurrentDate, 0)), 0))  ChurnRate_CurrentDate_Through_60Days

						/*CurrentDate vs Last90Days*/
						,UU_Last90Days			  - UU_Last90Days_CurrentDate				UU_NewContributer_CurrentDate_To_90Days
						,UU_Last90Days_CurrentDate + UU_CurrentDate -			UU_Last90Days	UU_Retained_CurrentDate_Through_90Days
						,UU_Last90Days			  - UU_CurrentDate							UU_Churned_CurrentDate_Through_90Days
						,	 (COALESCE((UU_Last90Days_CurrentDate + UU_CurrentDate - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_CurrentDate, 0)), 0))  RetentionRate_CurrentDate_Through_90Days
						,1.0-(COALESCE((UU_Last90Days_CurrentDate + UU_CurrentDate - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_CurrentDate, 0)), 0))  ChurnRate_CurrentDate_Through_90Days

						/*CurrentDate vs Last180Days*/
						,UU_Last180Days			  - UU_Last180Days_CurrentDate					UU_NewContributer_CurrentDate_To_180Days
						,UU_Last180Days_CurrentDate + UU_CurrentDate -			UU_Last180Days	UU_Retained_CurrentDate_Through_180Days
						,UU_Last180Days			  - UU_CurrentDate								UU_Churned_CurrentDate_Through_180Days
						,	 (COALESCE((UU_Last180Days_CurrentDate + UU_CurrentDate - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_CurrentDate, 0)), 0))   RetentionRate_CurrentDate_Through_180Days
						,1.0-(COALESCE((UU_Last180Days_CurrentDate + UU_CurrentDate - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_CurrentDate, 0)), 0))   ChurnRate_CurrentDate_Through_180Days

						/*CurrentDate vs Last360Days*/
						,UU_Last360Days			  - UU_Last360Days_CurrentDate				UU_NewContributer_CurrentDate_To_360Days
						,UU_Last360Days_CurrentDate + UU_CurrentDate -			UU_Last360Days	UU_Retained_CurrentDate_Through_360Days
						,UU_Last360Days			  - UU_CurrentDate							UU_Churned_CurrentDate_Through_360Days
						,	 (COALESCE((UU_Last360Days_CurrentDate + UU_CurrentDate - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_CurrentDate, 0)), 0))  RetentionRate_CurrentDate_Through_360Days
						,1.0-(COALESCE((UU_Last360Days_CurrentDate + UU_CurrentDate - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_CurrentDate, 0)), 0))  ChurnRate_CurrentDate_Through_360Days

						/*CurrentDate vs Last720Days*/
						,UU_Last720Days			  - UU_Last720Days_CurrentDate				UU_NewContributer_CurrentDate_To_720Days
						,UU_Last720Days_CurrentDate + UU_CurrentDate -			UU_Last720Days	UU_Retained_CurrentDate_Through_720Days
						,UU_Last720Days			  - UU_CurrentDate							UU_Churned_CurrentDate_Through_720Days
						,	 (COALESCE((UU_Last720Days_CurrentDate + UU_CurrentDate - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_CurrentDate, 0)), 0))  RetentionRate_CurrentDate_Through_720Days
						,1.0-(COALESCE((UU_Last720Days_CurrentDate + UU_CurrentDate - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_CurrentDate, 0)), 0))  ChurnRate_CurrentDate_Through_720Days

						/*TheDayBeforeCurrentDate vs Last7Days*/
						,UU_Last7Days			 - UU_Last7Days_TheDayBeforeCurrentDate					UU_NewContributer_TheDayBeforeCurrentDate_To_7Days
						,UU_Last7Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate -			UU_Last7Days	UU_Retained_TheDayBeforeCurrentDate_Through_7Days
						,UU_Last7Days			 - UU_TheDayBeforeCurrentDate								UU_Churned_TheDayBeforeCurrentDate_Through_7Days
						,	 (COALESCE((UU_Last7Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last7Days)*1.0 / (NULLIF(UU_Last7Days_TheDayBeforeCurrentDate, 0)), 0)) RetentionRate_TheDayBeforeCurrentDate_Through_7Days
						,1.0-(COALESCE((UU_Last7Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last7Days)*1.0 / (NULLIF(UU_Last7Days_TheDayBeforeCurrentDate, 0)), 0)) ChurnRate_TheDayBeforeCurrentDate_Through_7Days

						/*TheDayBeforeCurrentDate vs Last14Days*/
						,UU_Last14Days			 - UU_Last14Days_TheDayBeforeCurrentDate					UU_NewContributer_TheDayBeforeCurrentDate_To_14Days
						,UU_Last14Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate -			UU_Last14Days	UU_Retained_TheDayBeforeCurrentDate_Through_14Days
						,UU_Last14Days			 - UU_TheDayBeforeCurrentDate								UU_Churned_TheDayBeforeCurrentDate_Through_14Days
						,	 (COALESCE((UU_Last14Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last14Days)*1.0 / (NULLIF(UU_Last14Days_TheDayBeforeCurrentDate, 0)), 0)) RetentionRate_TheDayBeforeCurrentDate_Through_14Days
						,1.0-(COALESCE((UU_Last14Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last14Days)*1.0 / (NULLIF(UU_Last14Days_TheDayBeforeCurrentDate, 0)), 0)) ChurnRate_TheDayBeforeCurrentDate_Through_14Days

						/*TheDayBeforeCurrentDate vs Last30Days*/
						,UU_Last30Days			 - UU_Last30Days_TheDayBeforeCurrentDate					UU_NewContributer_TheDayBeforeCurrentDate_To_30Days
						,UU_Last30Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate -			UU_Last30Days	UU_Retained_TheDayBeforeCurrentDate_Through_30Days
						,UU_Last30Days			 - UU_TheDayBeforeCurrentDate								UU_Churned_TheDayBeforeCurrentDate_Through_30Days
						,	 (COALESCE((UU_Last30Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last30Days)*1.0 / (NULLIF(UU_Last30Days_TheDayBeforeCurrentDate, 0)), 0)) RetentionRate_TheDayBeforeCurrentDate_Through_30Days
						,1.0-(COALESCE((UU_Last30Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last30Days)*1.0 / (NULLIF(UU_Last30Days_TheDayBeforeCurrentDate, 0)), 0)) ChurnRate_TheDayBeforeCurrentDate_Through_30Days

						/*TheDayBeforeCurrentDate vs Last60Days*/
						,UU_Last60Days			  - UU_Last60Days_TheDayBeforeCurrentDate				UU_NewContributer_TheDayBeforeCurrentDate_To_60Days
						,UU_Last60Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate -			UU_Last60Days	UU_Retained_TheDayBeforeCurrentDate_Through_60Days
						,UU_Last60Days			  - UU_TheDayBeforeCurrentDate							UU_Churned_TheDayBeforeCurrentDate_Through_60Days
						,	 (COALESCE((UU_Last60Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last60Days)*1.0 / (NULLIF(UU_Last60Days_TheDayBeforeCurrentDate, 0)), 0))  RetentionRate_TheDayBeforeCurrentDate_Through_60Days
						,1.0-(COALESCE((UU_Last60Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last60Days)*1.0 / (NULLIF(UU_Last60Days_TheDayBeforeCurrentDate, 0)), 0))  ChurnRate_TheDayBeforeCurrentDate_Through_60Days

						/*TheDayBeforeCurrentDate vs Last90Days*/
						,UU_Last90Days			  - UU_Last90Days_TheDayBeforeCurrentDate				UU_NewContributer_TheDayBeforeCurrentDate_To_90Days
						,UU_Last90Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate -			UU_Last90Days	UU_Retained_TheDayBeforeCurrentDate_Through_90Days
						,UU_Last90Days			  - UU_TheDayBeforeCurrentDate							UU_Churned_TheDayBeforeCurrentDate_Through_90Days
						,	 (COALESCE((UU_Last90Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_TheDayBeforeCurrentDate, 0)), 0))  RetentionRate_TheDayBeforeCurrentDate_Through_90Days
						,1.0-(COALESCE((UU_Last90Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_TheDayBeforeCurrentDate, 0)), 0))  ChurnRate_TheDayBeforeCurrentDate_Through_90Days

						/*TheDayBeforeCurrentDate vs Last180Days*/
						,UU_Last180Days			  - UU_Last180Days_TheDayBeforeCurrentDate					UU_NewContributer_TheDayBeforeCurrentDate_To_180Days
						,UU_Last180Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate -			UU_Last180Days	UU_Retained_TheDayBeforeCurrentDate_Through_180Days
						,UU_Last180Days			  - UU_TheDayBeforeCurrentDate								UU_Churned_TheDayBeforeCurrentDate_Through_180Days
						,	 (COALESCE((UU_Last180Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_TheDayBeforeCurrentDate, 0)), 0))   RetentionRate_TheDayBeforeCurrentDate_Through_180Days
						,1.0-(COALESCE((UU_Last180Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_TheDayBeforeCurrentDate, 0)), 0))   ChurnRate_TheDayBeforeCurrentDate_Through_180Days

						/*TheDayBeforeCurrentDate vs Last360Days*/
						,UU_Last360Days			  - UU_Last360Days_TheDayBeforeCurrentDate				UU_NewContributer_TheDayBeforeCurrentDate_To_360Days
						,UU_Last360Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate -			UU_Last360Days	UU_Retained_TheDayBeforeCurrentDate_Through_360Days
						,UU_Last360Days			  - UU_TheDayBeforeCurrentDate							UU_Churned_TheDayBeforeCurrentDate_Through_360Days
						,	 (COALESCE((UU_Last360Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_TheDayBeforeCurrentDate, 0)), 0))  RetentionRate_TheDayBeforeCurrentDate_Through_360Days
						,1.0-(COALESCE((UU_Last360Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_TheDayBeforeCurrentDate, 0)), 0))  ChurnRate_TheDayBeforeCurrentDate_Through_360Days

						/*TheDayBeforeCurrentDate vs Last720Days*/
						,UU_Last720Days			  - UU_Last720Days_TheDayBeforeCurrentDate				UU_NewContributer_TheDayBeforeCurrentDate_To_720Days
						,UU_Last720Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate -			UU_Last720Days	UU_Retained_TheDayBeforeCurrentDate_Through_720Days
						,UU_Last720Days			  - UU_TheDayBeforeCurrentDate							UU_Churned_TheDayBeforeCurrentDate_Through_720Days
						,	 (COALESCE((UU_Last720Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_TheDayBeforeCurrentDate, 0)), 0))  RetentionRate_TheDayBeforeCurrentDate_Through_720Days
						,1.0-(COALESCE((UU_Last720Days_TheDayBeforeCurrentDate + UU_TheDayBeforeCurrentDate - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_TheDayBeforeCurrentDate, 0)), 0))  ChurnRate_TheDayBeforeCurrentDate_Through_720Days

						/*Last7Days vs Last14Days*/
						,UU_Last14Days			 - UU_Last14Days_Last7Days					UU_NewContributer_Last7Days_To_14Days
						,UU_Last14Days_Last7Days + UU_Last7Days -			UU_Last14Days	UU_Retained_Last7Days_Through_14Days
						,UU_Last14Days			 - UU_Last7Days								UU_Churned_Last7Days_Through_14Days
						,	 (COALESCE((UU_Last14Days_Last7Days + UU_Last7Days - UU_Last14Days)*1.0 / (NULLIF(UU_Last14Days_Last7Days, 0)), 0))	RetentionRate_Last7Days_Through_14Days
						,1.0-(COALESCE((UU_Last14Days_Last7Days + UU_Last7Days - UU_Last14Days)*1.0 / (NULLIF(UU_Last14Days_Last7Days, 0)), 0)) ChurnRate_Last7Days_Through_14Days

						/*Last7Days vs Last30Days*/
						,UU_Last30Days			 - UU_Last30Days_Last7Days					UU_NewContributer_Last7Days_To_30Days
						,UU_Last30Days_Last7Days + UU_Last7Days -			UU_Last30Days	UU_Retained_Last7Days_Through_30Days
						,UU_Last30Days			 - UU_Last7Days								UU_Churned_Last7Days_Through_30Days
						,	 (COALESCE((UU_Last30Days_Last7Days + UU_Last7Days - UU_Last30Days)*1.0 / (NULLIF(UU_Last30Days_Last7Days, 0)), 0))	RetentionRate_Last7Days_Through_30Days
						,1.0-(COALESCE((UU_Last30Days_Last7Days + UU_Last7Days - UU_Last30Days)*1.0 / (NULLIF(UU_Last30Days_Last7Days, 0)), 0)) ChurnRate_Last7Days_Through_30Days

						/*Last7Days vs Last60Days*/
						,UU_Last60Days			  - UU_Last60Days_Last7Days				UU_NewContributer_Last7Days_To_60Days
						,UU_Last60Days_Last7Days + UU_Last7Days -			UU_Last60Days	UU_Retained_Last7Days_Through_60Days
						,UU_Last60Days			  - UU_Last7Days							UU_Churned_Last7Days_Through_60Days
						,	 (COALESCE((UU_Last60Days_Last7Days + UU_Last7Days - UU_Last60Days)*1.0 / (NULLIF(UU_Last60Days_Last7Days, 0)), 0))	RetentionRate_Last7Days_Through_60Days
						,1.0-(COALESCE((UU_Last60Days_Last7Days + UU_Last7Days - UU_Last60Days)*1.0 / (NULLIF(UU_Last60Days_Last7Days, 0)), 0))  ChurnRate_Last7Days_Through_60Days

						/*Last7Days vs Last90Days*/
						,UU_Last90Days			  - UU_Last90Days_Last7Days				UU_NewContributer_Last7Days_To_90Days
						,UU_Last90Days_Last7Days + UU_Last7Days -			UU_Last90Days	UU_Retained_Last7Days_Through_90Days
						,UU_Last90Days			  - UU_Last7Days							UU_Churned_Last7Days_Through_90Days
						,	 (COALESCE((UU_Last90Days_Last7Days + UU_Last7Days - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_Last7Days, 0)), 0))	RetentionRate_Last7Days_Through_90Days
						,1.0-(COALESCE((UU_Last90Days_Last7Days + UU_Last7Days - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_Last7Days, 0)), 0))  ChurnRate_Last7Days_Through_90Days

						/*Last7Days vs Last180Days*/
						,UU_Last180Days			  - UU_Last180Days_Last7Days					UU_NewContributer_Last7Days_To_180Days
						,UU_Last180Days_Last7Days + UU_Last7Days -			UU_Last180Days	UU_Retained_Last7Days_Through_180Days
						,UU_Last180Days			  - UU_Last7Days								UU_Churned_Last7Days_Through_180Days
						,	 (COALESCE((UU_Last180Days_Last7Days + UU_Last7Days - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_Last7Days, 0)), 0))	RetentionRate_Last7Days_Through_180Days
						,1.0-(COALESCE((UU_Last180Days_Last7Days + UU_Last7Days - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_Last7Days, 0)), 0))   ChurnRate_Last7Days_Through_180Days

						/*Last7Days vs Last360Days*/
						,UU_Last360Days			  - UU_Last360Days_Last7Days				UU_NewContributer_Last7Days_To_360Days
						,UU_Last360Days_Last7Days + UU_Last7Days -			UU_Last360Days	UU_Retained_Last7Days_Through_360Days
						,UU_Last360Days			  - UU_Last7Days							UU_Churned_Last7Days_Through_360Days
						,	 (COALESCE((UU_Last360Days_Last7Days + UU_Last7Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last7Days, 0)), 0))	RetentionRate_Last7Days_Through_360Days
						,1.0-(COALESCE((UU_Last360Days_Last7Days + UU_Last7Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last7Days, 0)), 0))  ChurnRate_Last7Days_Through_360Days

						/*Last7Days vs Last720Days*/
						,UU_Last720Days			  - UU_Last720Days_Last7Days				UU_NewContributer_Last7Days_To_720Days
						,UU_Last720Days_Last7Days + UU_Last7Days -			UU_Last720Days	UU_Retained_Last7Days_Through_720Days
						,UU_Last720Days			  - UU_Last7Days							UU_Churned_Last7Days_Through_720Days
						,	 (COALESCE((UU_Last720Days_Last7Days + UU_Last7Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last7Days, 0)), 0))	RetentionRate_Last7Days_Through_720Days
						,1.0-(COALESCE((UU_Last720Days_Last7Days + UU_Last7Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last7Days, 0)), 0))  ChurnRate_Last7Days_Through_720Days

						/*Last14Days vs Last30Days*/
						,UU_Last30Days			 - UU_Last30Days_Last14Days					UU_NewContributer_Last14Days_To_30Days
						,UU_Last30Days_Last14Days + UU_Last14Days -			UU_Last30Days	UU_Retained_Last14Days_Through_30Days
						,UU_Last30Days			 - UU_Last14Days								UU_Churned_Last14Days_Through_30Days
						,	 (COALESCE((UU_Last30Days_Last14Days + UU_Last14Days - UU_Last30Days)*1.0 / (NULLIF(UU_Last30Days_Last14Days, 0)), 0))	RetentionRate_Last14Days_Through_30Days
						,1.0-(COALESCE((UU_Last30Days_Last14Days + UU_Last14Days - UU_Last30Days)*1.0 / (NULLIF(UU_Last30Days_Last14Days, 0)), 0)) ChurnRate_Last14Days_Through_30Days

						/*Last14Days vs Last60Days*/
						,UU_Last60Days			  - UU_Last60Days_Last14Days				UU_NewContributer_Last14Days_To_60Days
						,UU_Last60Days_Last14Days + UU_Last14Days -			UU_Last60Days	UU_Retained_Last14Days_Through_60Days
						,UU_Last60Days			  - UU_Last14Days							UU_Churned_Last14Days_Through_60Days
						,	 (COALESCE((UU_Last60Days_Last14Days + UU_Last14Days - UU_Last60Days)*1.0 / (NULLIF(UU_Last60Days_Last14Days, 0)), 0))	RetentionRate_Last14Days_Through_60Days
						,1.0-(COALESCE((UU_Last60Days_Last14Days + UU_Last14Days - UU_Last60Days)*1.0 / (NULLIF(UU_Last60Days_Last14Days, 0)), 0))  ChurnRate_Last14Days_Through_60Days

						/*Last14Days vs Last90Days*/
						,UU_Last90Days			  - UU_Last90Days_Last14Days				UU_NewContributer_Last14Days_To_90Days
						,UU_Last90Days_Last14Days + UU_Last14Days -			UU_Last90Days	UU_Retained_Last14Days_Through_90Days
						,UU_Last90Days			  - UU_Last14Days							UU_Churned_Last14Days_Through_90Days
						,	 (COALESCE((UU_Last90Days_Last14Days + UU_Last14Days - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_Last14Days, 0)), 0))	RetentionRate_Last14Days_Through_90Days
						,1.0-(COALESCE((UU_Last90Days_Last14Days + UU_Last14Days - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_Last14Days, 0)), 0))  ChurnRate_Last14Days_Through_90Days

						/*Last14Days vs Last180Days*/
						,UU_Last180Days			  - UU_Last180Days_Last14Days					UU_NewContributer_Last14Days_To_180Days
						,UU_Last180Days_Last14Days + UU_Last14Days -			UU_Last180Days	UU_Retained_Last14Days_Through_180Days
						,UU_Last180Days			  - UU_Last14Days								UU_Churned_Last14Days_Through_180Days
						,	 (COALESCE((UU_Last180Days_Last14Days + UU_Last14Days - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_Last14Days, 0)), 0))	RetentionRate_Last14Days_Through_180Days
						,1.0-(COALESCE((UU_Last180Days_Last14Days + UU_Last14Days - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_Last14Days, 0)), 0))   ChurnRate_Last14Days_Through_180Days

						/*Last14Days vs Last360Days*/
						,UU_Last360Days			  - UU_Last360Days_Last14Days				UU_NewContributer_Last14Days_To_360Days
						,UU_Last360Days_Last14Days + UU_Last14Days -			UU_Last360Days	UU_Retained_Last14Days_Through_360Days
						,UU_Last360Days			  - UU_Last14Days							UU_Churned_Last14Days_Through_360Days
						,	 (COALESCE((UU_Last360Days_Last14Days + UU_Last14Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last14Days, 0)), 0))	RetentionRate_Last14Days_Through_360Days
						,1.0-(COALESCE((UU_Last360Days_Last14Days + UU_Last14Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last14Days, 0)), 0))   ChurnRate_Last14Days_Through_360Days

						/*Last14Days vs Last720Days*/
						,UU_Last720Days			  - UU_Last720Days_Last14Days				UU_NewContributer_Last14Days_To_720Days
						,UU_Last720Days_Last14Days + UU_Last14Days -			UU_Last720Days	UU_Retained_Last14Days_Through_720Days
						,UU_Last720Days			  - UU_Last14Days							UU_Churned_Last14Days_Through_720Days
						,	 (COALESCE((UU_Last720Days_Last14Days + UU_Last14Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last14Days, 0)), 0))	RetentionRate_Last14Days_Through_720Days
						,1.0-(COALESCE((UU_Last720Days_Last14Days + UU_Last14Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last14Days, 0)), 0))   ChurnRate_Last14Days_Through_720Days

						/*Last30Days vs Last60Days*/
						,UU_Last60Days			  - UU_Last60Days_Last30Days				UU_NewContributer_Last30Days_To_60Days
						,UU_Last60Days_Last30Days + UU_Last30Days -			UU_Last60Days	UU_Retained_Last30Days_Through_60Days
						,UU_Last60Days			  - UU_Last30Days							UU_Churned_Last30Days_Through_60Days
						,	 (COALESCE((UU_Last60Days_Last30Days + UU_Last30Days - UU_Last60Days)*1.0 / (NULLIF(UU_Last60Days_Last30Days, 0)), 0))	RetentionRate_Last30Days_Through_60Days
						,1.0-(COALESCE((UU_Last60Days_Last30Days + UU_Last30Days - UU_Last60Days)*1.0 / (NULLIF(UU_Last60Days_Last30Days, 0)), 0))  ChurnRate_Last30Days_Through_60Days

						/*Last30Days vs Last90Days*/
						,UU_Last90Days			  - UU_Last90Days_Last30Days				UU_NewContributer_Last30Days_To_90Days
						,UU_Last90Days_Last30Days + UU_Last30Days -			UU_Last90Days	UU_Retained_Last30Days_Through_90Days
						,UU_Last90Days			  - UU_Last30Days							UU_Churned_Last30Days_Through_90Days
						,	 (COALESCE((UU_Last90Days_Last30Days + UU_Last30Days - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_Last30Days, 0)), 0))	RetentionRate_Last30Days_Through_90Days
						,1.0-(COALESCE((UU_Last90Days_Last30Days + UU_Last30Days - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_Last30Days, 0)), 0))  ChurnRate_Last30Days_Through_90Days

						/*Last30Days vs Last180Days*/
						,UU_Last180Days			  - UU_Last180Days_Last30Days					UU_NewContributer_Last30Days_To_180Days
						,UU_Last180Days_Last30Days + UU_Last30Days -			UU_Last180Days	UU_Retained_Last30Days_Through_180Days
						,UU_Last180Days			  - UU_Last30Days								UU_Churned_Last30Days_Through_180Days
						,	 (COALESCE((UU_Last180Days_Last30Days + UU_Last30Days - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_Last30Days, 0)), 0))	RetentionRate_Last30Days_Through_180Days
						,1.0-(COALESCE((UU_Last180Days_Last30Days + UU_Last30Days - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_Last30Days, 0)), 0))   ChurnRate_Last30Days_Through_180Days

						/*Last30Days vs Last360Days*/
						,UU_Last360Days			  - UU_Last360Days_Last30Days				UU_NewContributer_Last30Days_To_360Days
						,UU_Last360Days_Last30Days + UU_Last30Days -			UU_Last360Days	UU_Retained_Last30Days_Through_360Days
						,UU_Last360Days			  - UU_Last30Days							UU_Churned_Last30Days_Through_360Days
						,	 (COALESCE((UU_Last360Days_Last30Days + UU_Last30Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last30Days, 0)), 0))  RetentionRate_Last30Days_Through_360Days
						,1.0-(COALESCE((UU_Last360Days_Last30Days + UU_Last30Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last30Days, 0)), 0))  ChurnRate_Last30Days_Through_360Days

						/*Last30Days vs Last720Days*/
						,UU_Last720Days			  - UU_Last720Days_Last30Days				UU_NewContributer_Last30Days_To_720Days
						,UU_Last720Days_Last30Days + UU_Last30Days -			UU_Last720Days	UU_Retained_Last30Days_Through_720Days
						,UU_Last720Days			  - UU_Last30Days							UU_Churned_Last30Days_Through_720Days
						,	 (COALESCE((UU_Last720Days_Last30Days + UU_Last30Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last30Days, 0)), 0))  RetentionRate_Last30Days_Through_720Days
						,1.0-(COALESCE((UU_Last720Days_Last30Days + UU_Last30Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last30Days, 0)), 0))  ChurnRate_Last30Days_Through_720Days

						/*Last60Days vs Last90Days*/
						,UU_Last90Days			  - UU_Last90Days_Last60Days				UU_NewContributer_Last60Days_To_90Days
						,UU_Last90Days_Last60Days + UU_Last60Days -			UU_Last90Days	UU_Retained_Last60Days_Through_90Days
						,UU_Last90Days			  - UU_Last60Days							UU_Churned_Last60Days_Through_90Days
						,	 (COALESCE((UU_Last90Days_Last60Days + UU_Last60Days - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_Last60Days, 0)), 0))	RetentionRate_Last60Days_Through_90Days
						,1.0-(COALESCE((UU_Last90Days_Last60Days + UU_Last60Days - UU_Last90Days)*1.0 / (NULLIF(UU_Last90Days_Last60Days, 0)), 0))  ChurnRate_Last60Days_Through_90Days

						/*Last60Days vs Last180Days*/
						,UU_Last180Days			  - UU_Last180Days_Last60Days					UU_NewContributer_Last60Days_To_180Days
						,UU_Last180Days_Last60Days + UU_Last60Days -			UU_Last180Days	UU_Retained_Last60Days_Through_180Days
						,UU_Last180Days			  - UU_Last60Days								UU_Churned_Last60Days_Through_180Days
						,	 (COALESCE((UU_Last180Days_Last60Days + UU_Last60Days - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_Last60Days, 0)), 0))	RetentionRate_Last60Days_Through_180Days
						,1.0-(COALESCE((UU_Last180Days_Last60Days + UU_Last60Days - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_Last60Days, 0)), 0))   ChurnRate_Last60Days_Through_180Days

						/*Last60Days vs Last360Days*/
						,UU_Last360Days			  - UU_Last360Days_Last60Days				UU_NewContributer_Last60Days_To_360Days
						,UU_Last360Days_Last60Days + UU_Last60Days -			UU_Last360Days	UU_Retained_Last60Days_Through_360Days
						,UU_Last360Days			  - UU_Last60Days							UU_Churned_Last60Days_Through_360Days
						,	 (COALESCE((UU_Last360Days_Last60Days + UU_Last60Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last60Days, 0)), 0))  RetentionRate_Last60Days_Through_360Days
						,1.0-(COALESCE((UU_Last360Days_Last60Days + UU_Last60Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last60Days, 0)), 0))  ChurnRate_Last60Days_Through_360Days

						/*Last60Days vs Last720Days*/
						,UU_Last720Days			  - UU_Last720Days_Last60Days				UU_NewContributer_Last60Days_To_720Days
						,UU_Last720Days_Last60Days + UU_Last60Days -			UU_Last720Days	UU_Retained_Last60Days_Through_720Days
						,UU_Last720Days			  - UU_Last60Days							UU_Churned_Last60Days_Through_720Days
						,	 (COALESCE((UU_Last720Days_Last60Days + UU_Last60Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last60Days, 0)), 0))  RetentionRate_Last60Days_Through_720Days
						,1.0-(COALESCE((UU_Last720Days_Last60Days + UU_Last60Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last60Days, 0)), 0))  ChurnRate_Last60Days_Through_720Days

						/*Last90Days vs Last180Days*/
						,UU_Last180Days			  - UU_Last180Days_Last90Days					UU_NewContributer_Last90Days_To_180Days
						,UU_Last180Days_Last90Days + UU_Last90Days -			UU_Last180Days	UU_Retained_Last90Days_Through_180Days
						,UU_Last180Days			  - UU_Last90Days								UU_Churned_Last90Days_Through_180Days
						,	 (COALESCE((UU_Last180Days_Last90Days + UU_Last90Days - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_Last90Days, 0)), 0))	RetentionRate_Last90Days_Through_180Days
						,1.0-(COALESCE((UU_Last180Days_Last90Days + UU_Last90Days - UU_Last180Days)*1.0 / (NULLIF(UU_Last180Days_Last90Days, 0)), 0))   ChurnRate_Last90Days_Through_180Days

						/*Last90Days vs Last360Days*/
						,UU_Last360Days			  - UU_Last360Days_Last90Days				UU_NewContributer_Last90Days_To_360Days
						,UU_Last360Days_Last90Days + UU_Last90Days -			UU_Last360Days	UU_Retained_Last90Days_Through_360Days
						,UU_Last360Days			  - UU_Last90Days							UU_Churned_Last90Days_Through_360Days
						,	 (COALESCE((UU_Last360Days_Last90Days + UU_Last90Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last90Days, 0)), 0))  RetentionRate_Last90Days_Through_360Days
						,1.0-(COALESCE((UU_Last360Days_Last90Days + UU_Last90Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last90Days, 0)), 0))  ChurnRate_Last90Days_Through_360Days

						/*Last90Days vs Last720Days*/
						,UU_Last720Days			  - UU_Last720Days_Last90Days				UU_NewContributer_Last90Days_To_720Days
						,UU_Last720Days_Last90Days + UU_Last90Days -			UU_Last720Days	UU_Retained_Last90Days_Through_720Days
						,UU_Last720Days			  - UU_Last90Days							UU_Churned_Last90Days_Through_720Days
						,	 (COALESCE((UU_Last720Days_Last90Days + UU_Last90Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last90Days, 0)), 0))	RetentionRate_Last90Days_Through_720Days
						,1.0-(COALESCE((UU_Last720Days_Last90Days + UU_Last90Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last90Days, 0)), 0))   ChurnRate_Last90Days_Through_720Days


						/*Last180Days vs Last360Days*/
						,UU_Last360Days			  - UU_Last360Days_Last180Days				UU_NewContributer_Last180Days_To_360Days
						,UU_Last360Days_Last180Days + UU_Last180Days -			UU_Last360Days	UU_Retained_Last180Days_Through_360Days
						,UU_Last360Days			  - UU_Last180Days							UU_Churned_Last180Days_Through_360Days
						,	 (COALESCE((UU_Last360Days_Last180Days + UU_Last180Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last180Days, 0)), 0))  RetentionRate_Last180Days_Through_360Days
						,1.0-(COALESCE((UU_Last360Days_Last180Days + UU_Last180Days - UU_Last360Days)*1.0 / (NULLIF(UU_Last360Days_Last180Days, 0)), 0))  ChurnRate_Last180Days_Through_360Days

						/*Last180Days vs Last720Days*/
						,UU_Last720Days			  - UU_Last720Days_Last180Days				UU_NewContributer_Last180Days_To_720Days
						,UU_Last720Days_Last180Days + UU_Last180Days -			UU_Last720Days	UU_Retained_Last180Days_Through_720Days
						,UU_Last720Days			  - UU_Last180Days							UU_Churned_Last180Days_Through_720Days
						,	 (COALESCE((UU_Last720Days_Last180Days + UU_Last180Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last180Days, 0)), 0))  RetentionRate_Last180Days_Through_720Days
						,1.0-(COALESCE((UU_Last720Days_Last180Days + UU_Last180Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last180Days, 0)), 0))  ChurnRate_Last180Days_Through_720Days


						/*Last360Days vs Last720Days*/
						,UU_Last720Days			    - UU_Last720Days_Last360Days					UU_NewContributer_Last360Days_To_720Days
						,UU_Last720Days_Last360Days + UU_Last360Days -			UU_Last720Days		UU_Retained_Last360Days_Through_720Days
						,UU_Last720Days			    - UU_Last360Days								UU_Churned_Last360Days_Through_720Days
						,	 (COALESCE((UU_Last720Days_Last360Days + UU_Last360Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last360Days, 0)), 0))  RetentionRate_Last360Days_Through_720Days
						,1.0-(COALESCE((UU_Last720Days_Last360Days + UU_Last360Days - UU_Last720Days)*1.0 / (NULLIF(UU_Last720Days_Last360Days, 0)), 0))  ChurnRate_Last360Days_Through_720Days
		FROM DummyForStructure DFS With (Nolock)
		LEFT JOIN #K1 A1 ON DFS.DummyForJoining = A1.DummyForJoining
		LEFT JOIN #K2 A2 ON DFS.DummyForJoining = A2.DummyForJoining
		), EngagingDataWith_ChurnComment AS
		(
		SELECT
			 0 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxCurrentDate															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxCurrentDateRegisteredCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxCurrentDate_Over_UU_CurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_FirstTxCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_CurrentDate			RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,1 RangesAreSymmetric
			,2 AllRange
			,1 CurrentRange
			,1 PreviousRange
			,UU_CurrentDate UU_CurrentRange
			,UU_Retained_CurrentDate_Through_TheDayBeforeCurrentDate + UU_Churned_CurrentDate_Through_TheDayBeforeCurrentDate UU_PreviousRange
			,UU_NewContributer_CurrentDate_To_TheDayBeforeCurrentDate	UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_CurrentDate_Through_TheDayBeforeCurrentDate	UU_Retained
			,UU_Churned_CurrentDate_Through_TheDayBeforeCurrentDate		UU_Churned
			,RetentionRate_CurrentDate_Through_TheDayBeforeCurrentDate	RetentionRate
			,ChurnRate_CurrentDate_Through_TheDayBeforeCurrentDate		ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 0 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxCurrentDate															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxCurrentDateRegisteredCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxCurrentDate_Over_UU_CurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_FirstTxCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_CurrentDate			RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,7 AllRange
			,1 CurrentRange
			,6 PreviousRange
			,UU_CurrentDate UU_CurrentRange
			,UU_Retained_CurrentDate_Through_7Days + UU_Churned_CurrentDate_Through_7Days UU_PreviousRange
			,UU_NewContributer_CurrentDate_To_7Days										  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_CurrentDate_Through_7Days										  UU_Retained
			,UU_Churned_CurrentDate_Through_7Days										  UU_Churned
			,RetentionRate_CurrentDate_Through_7Days									  RetentionRate
			,ChurnRate_CurrentDate_Through_7Days										  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 0 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxCurrentDate															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxCurrentDateRegisteredCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxCurrentDate_Over_UU_CurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_FirstTxCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_CurrentDate			RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,14 AllRange
			,1 CurrentRange
			,13 PreviousRange
			,UU_CurrentDate UU_CurrentRange
			,UU_Retained_CurrentDate_Through_14Days + UU_Churned_CurrentDate_Through_14Days UU_PreviousRange
			,UU_NewContributer_CurrentDate_To_14Days										UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_CurrentDate_Through_14Days										    UU_Retained
			,UU_Churned_CurrentDate_Through_14Days										    UU_Churned
			,RetentionRate_CurrentDate_Through_14Days									    RetentionRate
			,ChurnRate_CurrentDate_Through_14Days										    ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 0 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxCurrentDate															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxCurrentDateRegisteredCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxCurrentDate_Over_UU_CurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_FirstTxCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_CurrentDate			RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,30 AllRange
			,1 CurrentRange
			,29 PreviousRange
			,UU_CurrentDate UU_CurrentRange
			,UU_Retained_CurrentDate_Through_30Days + UU_Churned_CurrentDate_Through_30Days UU_PreviousRange
			,UU_NewContributer_CurrentDate_To_30Days										UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_CurrentDate_Through_30Days											UU_Retained
			,UU_Churned_CurrentDate_Through_30Days											UU_Churned
			,RetentionRate_CurrentDate_Through_30Days										RetentionRate
			,ChurnRate_CurrentDate_Through_30Days											ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 0 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxCurrentDate															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxCurrentDateRegisteredCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxCurrentDate_Over_UU_CurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_FirstTxCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_CurrentDate			RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,60 AllRange
			,1 CurrentRange
			,59 PreviousRange
			,UU_CurrentDate UU_CurrentRange
			,UU_Retained_CurrentDate_Through_60Days + UU_Churned_CurrentDate_Through_60Days UU_PreviousRange
			,UU_NewContributer_CurrentDate_To_60Days									  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_CurrentDate_Through_60Days										  UU_Retained
			,UU_Churned_CurrentDate_Through_60Days										  UU_Churned
			,RetentionRate_CurrentDate_Through_60Days									  RetentionRate
			,ChurnRate_CurrentDate_Through_60Days										  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 0 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxCurrentDate															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxCurrentDateRegisteredCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxCurrentDate_Over_UU_CurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_FirstTxCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_CurrentDate			RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,90 AllRange
			,1 CurrentRange
			,89 PreviousRange
			,UU_CurrentDate UU_CurrentRange
			,UU_Retained_CurrentDate_Through_90Days + UU_Churned_CurrentDate_Through_90Days UU_PreviousRange
			,UU_NewContributer_CurrentDate_To_90Days									    UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_CurrentDate_Through_90Days										    UU_Retained
			,UU_Churned_CurrentDate_Through_90Days										    UU_Churned
			,RetentionRate_CurrentDate_Through_90Days									    RetentionRate
			,ChurnRate_CurrentDate_Through_90Days										    ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 0 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxCurrentDate															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxCurrentDateRegisteredCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxCurrentDate_Over_UU_CurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_FirstTxCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_CurrentDate			RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,180 AllRange
			,1 CurrentRange
			,179 PreviousRange
			,UU_CurrentDate UU_CurrentRange
			,UU_Retained_CurrentDate_Through_180Days + UU_Churned_CurrentDate_Through_180Days UU_PreviousRange
			,UU_NewContributer_CurrentDate_To_180Days										  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_CurrentDate_Through_180Days										  UU_Retained
			,UU_Churned_CurrentDate_Through_180Days											  UU_Churned
			,RetentionRate_CurrentDate_Through_180Days										  RetentionRate
			,ChurnRate_CurrentDate_Through_180Days											  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 0 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxCurrentDate															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxCurrentDateRegisteredCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxCurrentDate_Over_UU_CurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_FirstTxCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_CurrentDate			RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,360 AllRange
			,1 CurrentRange
			,359 PreviousRange
			,UU_CurrentDate UU_CurrentRange
			,UU_Retained_CurrentDate_Through_360Days + UU_Churned_CurrentDate_Through_360Days UU_PreviousRange
			,UU_NewContributer_CurrentDate_To_360Days										  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_CurrentDate_Through_360Days										  UU_Retained
			,UU_Churned_CurrentDate_Through_360Days											  UU_Churned
			,RetentionRate_CurrentDate_Through_360Days										  RetentionRate
			,ChurnRate_CurrentDate_Through_360Days											  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 0 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxCurrentDate															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxCurrentDateRegisteredCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxCurrentDate_Over_UU_CurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_FirstTxCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxCurrentDateRegisteredCurrentDate_Over_UU_CurrentDate			RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,720 AllRange
			,1 CurrentRange
			,719 PreviousRange
			,UU_CurrentDate UU_CurrentRange
			,UU_Retained_CurrentDate_Through_720Days + UU_Churned_CurrentDate_Through_720Days UU_PreviousRange
			,UU_NewContributer_CurrentDate_To_720Days										  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_CurrentDate_Through_720Days										  UU_Retained
			,UU_Churned_CurrentDate_Through_720Days											  UU_Churned
			,RetentionRate_CurrentDate_Through_720Days										  RetentionRate
			,ChurnRate_CurrentDate_Through_720Days											  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 1 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxTheDayBeforeCurrentDate																		UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxTheDayBeforeCurrentDate_Over_UU_TheDayBeforeCurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,7 AllRange
			,2 CurrentRange
			,5 PreviousRange
			,UU_TheDayBeforeCurrentDate UU_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_7Days + UU_Churned_TheDayBeforeCurrentDate_Through_7Days UU_PreviousRange
			,UU_NewContributer_TheDayBeforeCurrentDate_To_7Days													  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_7Days													  UU_Retained
			,UU_Churned_TheDayBeforeCurrentDate_Through_7Days													  UU_Churned
			,RetentionRate_TheDayBeforeCurrentDate_Through_7Days												  RetentionRate
			,ChurnRate_TheDayBeforeCurrentDate_Through_7Days													  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 1 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxTheDayBeforeCurrentDate																		UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxTheDayBeforeCurrentDate_Over_UU_TheDayBeforeCurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,14 AllRange
			,2 CurrentRange
			,12 PreviousRange
			,UU_TheDayBeforeCurrentDate UU_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_14Days + UU_Churned_TheDayBeforeCurrentDate_Through_14Days UU_PreviousRange
			,UU_NewContributer_TheDayBeforeCurrentDate_To_14Days													UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_14Days													    UU_Retained
			,UU_Churned_TheDayBeforeCurrentDate_Through_14Days													    UU_Churned
			,RetentionRate_TheDayBeforeCurrentDate_Through_14Days												    RetentionRate
			,ChurnRate_TheDayBeforeCurrentDate_Through_14Days													    ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 1 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxTheDayBeforeCurrentDate																		UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxTheDayBeforeCurrentDate_Over_UU_TheDayBeforeCurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,30 AllRange
			,2 CurrentRange
			,28 PreviousRange
			,UU_TheDayBeforeCurrentDate UU_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_30Days + UU_Churned_TheDayBeforeCurrentDate_Through_30Days UU_PreviousRange
			,UU_NewContributer_TheDayBeforeCurrentDate_To_30Days													UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_30Days													    UU_Retained
			,UU_Churned_TheDayBeforeCurrentDate_Through_30Days													    UU_Churned
			,RetentionRate_TheDayBeforeCurrentDate_Through_30Days												    RetentionRate
			,ChurnRate_TheDayBeforeCurrentDate_Through_30Days													    ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 1 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxTheDayBeforeCurrentDate																		UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxTheDayBeforeCurrentDate_Over_UU_TheDayBeforeCurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,60 AllRange
			,2 CurrentRange
			,58 PreviousRange
			,UU_TheDayBeforeCurrentDate UU_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_60Days + UU_Churned_TheDayBeforeCurrentDate_Through_60Days UU_PreviousRange
			,UU_NewContributer_TheDayBeforeCurrentDate_To_60Days													UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_60Days													    UU_Retained
			,UU_Churned_TheDayBeforeCurrentDate_Through_60Days													    UU_Churned
			,RetentionRate_TheDayBeforeCurrentDate_Through_60Days												    RetentionRate
			,ChurnRate_TheDayBeforeCurrentDate_Through_60Days													    ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 1 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxTheDayBeforeCurrentDate																		UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxTheDayBeforeCurrentDate_Over_UU_TheDayBeforeCurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,90 AllRange
			,2 CurrentRange
			,88 PreviousRange
			,UU_TheDayBeforeCurrentDate UU_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_90Days + UU_Churned_TheDayBeforeCurrentDate_Through_90Days UU_PreviousRange
			,UU_NewContributer_TheDayBeforeCurrentDate_To_90Days													UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_90Days													    UU_Retained
			,UU_Churned_TheDayBeforeCurrentDate_Through_90Days													    UU_Churned
			,RetentionRate_TheDayBeforeCurrentDate_Through_90Days												    RetentionRate
			,ChurnRate_TheDayBeforeCurrentDate_Through_90Days													    ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 1 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxTheDayBeforeCurrentDate																		UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxTheDayBeforeCurrentDate_Over_UU_TheDayBeforeCurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,180 AllRange
			,2 CurrentRange
			,178 PreviousRange
			,UU_TheDayBeforeCurrentDate UU_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_180Days + UU_Churned_TheDayBeforeCurrentDate_Through_180Days UU_PreviousRange
			,UU_NewContributer_TheDayBeforeCurrentDate_To_180Days													  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_180Days													  UU_Retained
			,UU_Churned_TheDayBeforeCurrentDate_Through_180Days														  UU_Churned
			,RetentionRate_TheDayBeforeCurrentDate_Through_180Days													  RetentionRate
			,ChurnRate_TheDayBeforeCurrentDate_Through_180Days														  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 1 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxTheDayBeforeCurrentDate																		UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxTheDayBeforeCurrentDate_Over_UU_TheDayBeforeCurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,360 AllRange
			,2 CurrentRange
			,358 PreviousRange
			,UU_TheDayBeforeCurrentDate UU_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_360Days + UU_Churned_TheDayBeforeCurrentDate_Through_360Days UU_PreviousRange
			,UU_NewContributer_TheDayBeforeCurrentDate_To_360Days													  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_360Days													  UU_Retained
			,UU_Churned_TheDayBeforeCurrentDate_Through_360Days													      UU_Churned
			,RetentionRate_TheDayBeforeCurrentDate_Through_360Days												      RetentionRate
			,ChurnRate_TheDayBeforeCurrentDate_Through_360Days													      ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 1 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxTheDayBeforeCurrentDate																		UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxTheDayBeforeCurrentDateRegisteredTheDayBeforeCurrentDate										UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxTheDayBeforeCurrentDate_Over_UU_TheDayBeforeCurrentDate								RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxTheDayBeforeCurrentDateRegisteredCurrentDate_Over_UU_FirstTxTheDayBeforeCurrentDate	RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,720 AllRange
			,2 CurrentRange
			,718 PreviousRange
			,UU_TheDayBeforeCurrentDate UU_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_720Days + UU_Churned_TheDayBeforeCurrentDate_Through_720Days UU_PreviousRange
			,UU_NewContributer_TheDayBeforeCurrentDate_To_720Days													  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_TheDayBeforeCurrentDate_Through_720Days													  UU_Retained
			,UU_Churned_TheDayBeforeCurrentDate_Through_720Days													      UU_Churned
			,RetentionRate_TheDayBeforeCurrentDate_Through_720Days												      RetentionRate
			,ChurnRate_TheDayBeforeCurrentDate_Through_720Days													      ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT
			 2 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast7Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast7DaysRegistered7Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast7Days_Over_UU_Last7Days										RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_FirstTxInLast7Days				RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_Last7Days						RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,1 RangesAreSymmetric
			,14 AllRange
			,7 CurrentRange
			,7 PreviousRange
			,UU_Last7Days UU_CurrentRange
			,UU_Retained_Last7Days_Through_14Days + UU_Churned_Last7Days_Through_14Days			UU_PreviousRange
			,UU_NewContributer_Last7Days_To_14Days												UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last7Days_Through_14Days												UU_Retained
			,UU_Churned_Last7Days_Through_14Days												UU_Churned
			,RetentionRate_Last7Days_Through_14Days												RetentionRate
			,ChurnRate_Last7Days_Through_14Days													ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 2 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast7Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast7DaysRegistered7Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast7Days_Over_UU_Last7Days										RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_FirstTxInLast7Days				RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_Last7Days						RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,30 AllRange
			,7  CurrentRange
			,23 PreviousRange
			,UU_Last7Days UU_CurrentRange
			,UU_Retained_Last7Days_Through_30Days + UU_Churned_Last7Days_Through_30Days			UU_PreviousRange
			,UU_NewContributer_Last7Days_To_30Days												UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last7Days_Through_30Days												UU_Retained
			,UU_Churned_Last7Days_Through_30Days												UU_Churned
			,RetentionRate_Last7Days_Through_30Days												RetentionRate
			,ChurnRate_Last7Days_Through_30Days													ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 2 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast7Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast7DaysRegistered7Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast7Days_Over_UU_Last7Days										RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_FirstTxInLast7Days				RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_Last7Days						RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,60 AllRange
			,7  CurrentRange
			,53 PreviousRange
			,UU_Last7Days UU_CurrentRange
			,UU_Retained_Last7Days_Through_60Days + UU_Churned_Last7Days_Through_60Days							  UU_PreviousRange
			,UU_NewContributer_Last7Days_To_60Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last7Days_Through_60Days																  UU_Retained
			,UU_Churned_Last7Days_Through_60Days																  UU_Churned
			,RetentionRate_Last7Days_Through_60Days																  RetentionRate
			,ChurnRate_Last7Days_Through_60Days																	  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 2 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast7Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast7DaysRegistered7Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast7Days_Over_UU_Last7Days										RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_FirstTxInLast7Days				RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_Last7Days						RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,90 AllRange
			,7 CurrentRange
			,83 PreviousRange
			,UU_Last7Days UU_CurrentRange
			,UU_Retained_Last7Days_Through_90Days + UU_Churned_Last7Days_Through_90Days							  UU_PreviousRange
			,UU_NewContributer_Last7Days_To_90Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last7Days_Through_90Days																  UU_Retained
			,UU_Churned_Last7Days_Through_90Days																  UU_Churned
			,RetentionRate_Last7Days_Through_90Days																  RetentionRate
			,ChurnRate_Last7Days_Through_90Days																	  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 2 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast7Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast7DaysRegistered7Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast7Days_Over_UU_Last7Days										RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_FirstTxInLast7Days				RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_Last7Days						RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,180 AllRange
			,7 CurrentRange
			,173 PreviousRange
			,UU_Last7Days UU_CurrentRange
			,UU_Retained_Last7Days_Through_180Days + UU_Churned_Last7Days_Through_180Days							  UU_PreviousRange
			,UU_NewContributer_Last7Days_To_180Days																	  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last7Days_Through_180Days																	  UU_Retained
			,UU_Churned_Last7Days_Through_180Days																	  UU_Churned
			,RetentionRate_Last7Days_Through_180Days																  RetentionRate
			,ChurnRate_Last7Days_Through_180Days																	  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 2 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast7Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast7DaysRegistered7Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast7Days_Over_UU_Last7Days										RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_FirstTxInLast7Days				RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_Last7Days						RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,360 AllRange
			,7 CurrentRange
			,353 PreviousRange
			,UU_Last7Days UU_CurrentRange
			,UU_Retained_Last7Days_Through_360Days + UU_Churned_Last7Days_Through_360Days						  UU_PreviousRange
			,UU_NewContributer_Last7Days_To_360Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last7Days_Through_360Days																  UU_Retained
			,UU_Churned_Last7Days_Through_360Days																  UU_Churned
			,RetentionRate_Last7Days_Through_360Days															  RetentionRate
			,ChurnRate_Last7Days_Through_360Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 2 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast7Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast7DaysRegistered7Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast7Days_Over_UU_Last7Days										RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_FirstTxInLast7Days				RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast7DaysRegistered7Days_Over_UU_Last7Days						RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,720 AllRange
			,7   CurrentRange
			,713 PreviousRange
			,UU_Last7Days UU_CurrentRange
			,UU_Retained_Last7Days_Through_720Days + UU_Churned_Last7Days_Through_720Days						  UU_PreviousRange
			,UU_NewContributer_Last7Days_To_720Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last7Days_Through_720Days																  UU_Retained
			,UU_Churned_Last7Days_Through_720Days																  UU_Churned
			,RetentionRate_Last7Days_Through_720Days															  RetentionRate
			,ChurnRate_Last7Days_Through_720Days																  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT
			 3 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast14Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast14DaysRegistered14Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast14Days_Over_UU_Last14Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_FirstTxInLast14Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_Last14Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,30 AllRange
			,14 CurrentRange
			,16 PreviousRange
			,UU_Last14Days UU_CurrentRange
			,UU_Retained_Last14Days_Through_30Days + UU_Churned_Last14Days_Through_30Days						  UU_PreviousRange
			,UU_NewContributer_Last14Days_To_30Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last14Days_Through_30Days																  UU_Retained
			,UU_Churned_Last14Days_Through_30Days																  UU_Churned
			,RetentionRate_Last14Days_Through_30Days															  RetentionRate
			,ChurnRate_Last14Days_Through_30Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 3 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast14Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast14DaysRegistered14Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast14Days_Over_UU_Last14Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_FirstTxInLast14Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_Last14Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,60 AllRange
			,14 CurrentRange
			,46 PreviousRange
			,UU_Last14Days UU_CurrentRange
			,UU_Retained_Last14Days_Through_60Days + UU_Churned_Last14Days_Through_60Days						  UU_PreviousRange
			,UU_NewContributer_Last14Days_To_60Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last14Days_Through_60Days																  UU_Retained
			,UU_Churned_Last14Days_Through_60Days																  UU_Churned
			,RetentionRate_Last14Days_Through_60Days															  RetentionRate
			,ChurnRate_Last14Days_Through_60Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 3 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast14Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast14DaysRegistered14Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast14Days_Over_UU_Last14Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_FirstTxInLast14Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_Last14Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,90 AllRange
			,14 CurrentRange
			,76 PreviousRange
			,UU_Last14Days UU_CurrentRange
			,UU_Retained_Last14Days_Through_90Days + UU_Churned_Last14Days_Through_90Days						  UU_PreviousRange
			,UU_NewContributer_Last14Days_To_90Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last14Days_Through_90Days																  UU_Retained
			,UU_Churned_Last14Days_Through_90Days																  UU_Churned
			,RetentionRate_Last14Days_Through_90Days															  RetentionRate
			,ChurnRate_Last14Days_Through_90Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 3 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast14Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast14DaysRegistered14Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast14Days_Over_UU_Last14Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_FirstTxInLast14Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_Last14Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,180 AllRange
			,14 CurrentRange
			,166 PreviousRange
			,UU_Last14Days UU_CurrentRange
			,UU_Retained_Last14Days_Through_180Days + UU_Churned_Last14Days_Through_180Days							  UU_PreviousRange
			,UU_NewContributer_Last14Days_To_180Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last14Days_Through_180Days																	  UU_Retained
			,UU_Churned_Last14Days_Through_180Days																	  UU_Churned
			,RetentionRate_Last14Days_Through_180Days																  RetentionRate
			,ChurnRate_Last14Days_Through_180Days																	  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 3 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast14Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast14DaysRegistered14Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast14Days_Over_UU_Last14Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_FirstTxInLast14Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_Last14Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,360 AllRange
			,14 CurrentRange
			,346 PreviousRange
			,UU_Last14Days UU_CurrentRange
			,UU_Retained_Last14Days_Through_360Days + UU_Churned_Last14Days_Through_360Days						  UU_PreviousRange
			,UU_NewContributer_Last14Days_To_360Days															  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last14Days_Through_360Days																  UU_Retained
			,UU_Churned_Last14Days_Through_360Days																  UU_Churned
			,RetentionRate_Last14Days_Through_360Days															  RetentionRate
			,ChurnRate_Last14Days_Through_360Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 3 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast14Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast14DaysRegistered14Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast14Days_Over_UU_Last14Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_FirstTxInLast14Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast14DaysRegistered14Days_Over_UU_Last14Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,720 AllRange
			,14 CurrentRange
			,706 PreviousRange
			,UU_Last14Days UU_CurrentRange
			,UU_Retained_Last14Days_Through_720Days + UU_Churned_Last14Days_Through_720Days						  UU_PreviousRange
			,UU_NewContributer_Last14Days_To_720Days															  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last14Days_Through_720Days																  UU_Retained
			,UU_Churned_Last14Days_Through_720Days																  UU_Churned
			,RetentionRate_Last14Days_Through_720Days															  RetentionRate
			,ChurnRate_Last14Days_Through_720Days																  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT
			 4 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast30Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast30DaysRegistered30Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast30Days_Over_UU_Last30Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_FirstTxInLast30Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_Last30Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,1 RangesAreSymmetric
			,60 AllRange
			,30 CurrentRange
			,30 PreviousRange
			,UU_Last30Days UU_CurrentRange
			,UU_Retained_Last30Days_Through_60Days + UU_Churned_Last30Days_Through_60Days						  UU_PreviousRange
			,UU_NewContributer_Last30Days_To_60Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last30Days_Through_60Days																  UU_Retained
			,UU_Churned_Last30Days_Through_60Days																  UU_Churned
			,RetentionRate_Last30Days_Through_60Days															  RetentionRate
			,ChurnRate_Last30Days_Through_60Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 4 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast30Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast30DaysRegistered30Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast30Days_Over_UU_Last30Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_FirstTxInLast30Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_Last30Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,90 AllRange
			,30 CurrentRange
			,60 PreviousRange
			,UU_Last30Days UU_CurrentRange
			,UU_Retained_Last30Days_Through_90Days + UU_Churned_Last30Days_Through_90Days						  UU_PreviousRange
			,UU_NewContributer_Last30Days_To_90Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last30Days_Through_90Days																  UU_Retained
			,UU_Churned_Last30Days_Through_90Days																  UU_Churned
			,RetentionRate_Last30Days_Through_90Days															  RetentionRate
			,ChurnRate_Last30Days_Through_90Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 4 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast30Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast30DaysRegistered30Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast30Days_Over_UU_Last30Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_FirstTxInLast30Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_Last30Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,180 AllRange
			,30 CurrentRange
			,150 PreviousRange
			,UU_Last30Days UU_CurrentRange
			,UU_Retained_Last30Days_Through_180Days + UU_Churned_Last30Days_Through_180Days							  UU_PreviousRange
			,UU_NewContributer_Last30Days_To_180Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last30Days_Through_180Days																	  UU_Retained
			,UU_Churned_Last30Days_Through_180Days																	  UU_Churned
			,RetentionRate_Last30Days_Through_180Days																  RetentionRate
			,ChurnRate_Last30Days_Through_180Days																	  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 4 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast30Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast30DaysRegistered30Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast30Days_Over_UU_Last30Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_FirstTxInLast30Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_Last30Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,360 AllRange
			,30 CurrentRange
			,330 PreviousRange
			,UU_Last30Days UU_CurrentRange
			,UU_Retained_Last30Days_Through_360Days + UU_Churned_Last30Days_Through_360Days						  UU_PreviousRange
			,UU_NewContributer_Last30Days_To_360Days															  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last30Days_Through_360Days																  UU_Retained
			,UU_Churned_Last30Days_Through_360Days																  UU_Churned
			,RetentionRate_Last30Days_Through_360Days															  RetentionRate
			,ChurnRate_Last30Days_Through_360Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 4 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast30Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast30DaysRegistered30Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast30Days_Over_UU_Last30Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_FirstTxInLast30Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast30DaysRegistered30Days_Over_UU_Last30Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,720 AllRange
			,30 CurrentRange
			,690 PreviousRange
			,UU_Last30Days UU_CurrentRange
			,UU_Retained_Last30Days_Through_720Days + UU_Churned_Last30Days_Through_720Days						  UU_PreviousRange
			,UU_NewContributer_Last30Days_To_720Days															  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last30Days_Through_720Days																  UU_Retained
			,UU_Churned_Last30Days_Through_720Days																  UU_Churned
			,RetentionRate_Last30Days_Through_720Days															  RetentionRate
			,ChurnRate_Last30Days_Through_720Days																  ChurnRate
		FROM RawData_CTE


		UNION ALL
		SELECT
			 5 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast60Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast60DaysRegistered60Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast60Days_Over_UU_Last60Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast60DaysRegistered60Days_Over_UU_FirstTxInLast60Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast60DaysRegistered60Days_Over_UU_Last60Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,90 AllRange
			,60 CurrentRange
			,30 PreviousRange
			,UU_Last60Days UU_CurrentRange
			,UU_Retained_Last60Days_Through_90Days + UU_Churned_Last60Days_Through_90Days						  UU_PreviousRange
			,UU_NewContributer_Last60Days_To_90Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last60Days_Through_90Days																  UU_Retained
			,UU_Churned_Last60Days_Through_90Days																  UU_Churned
			,RetentionRate_Last60Days_Through_90Days															  RetentionRate
			,ChurnRate_Last60Days_Through_90Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 5 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast60Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast60DaysRegistered60Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast60Days_Over_UU_Last60Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast60DaysRegistered60Days_Over_UU_FirstTxInLast60Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast60DaysRegistered60Days_Over_UU_Last60Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,180 AllRange
			,60 CurrentRange
			,120 PreviousRange
			,UU_Last60Days UU_CurrentRange
			,UU_Retained_Last60Days_Through_180Days + UU_Churned_Last60Days_Through_180Days							  UU_PreviousRange
			,UU_NewContributer_Last60Days_To_180Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last60Days_Through_180Days																	  UU_Retained
			,UU_Churned_Last60Days_Through_180Days																	  UU_Churned
			,RetentionRate_Last60Days_Through_180Days																  RetentionRate
			,ChurnRate_Last60Days_Through_180Days																	  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 5 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast60Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast60DaysRegistered60Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast60Days_Over_UU_Last60Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast60DaysRegistered60Days_Over_UU_FirstTxInLast60Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast60DaysRegistered60Days_Over_UU_Last60Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,360 AllRange
			,60 CurrentRange
			,300 PreviousRange
			,UU_Last60Days UU_CurrentRange
			,UU_Retained_Last60Days_Through_360Days + UU_Churned_Last60Days_Through_360Days						  UU_PreviousRange
			,UU_NewContributer_Last60Days_To_360Days															  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last60Days_Through_360Days																  UU_Retained
			,UU_Churned_Last60Days_Through_360Days																  UU_Churned
			,RetentionRate_Last60Days_Through_360Days															  RetentionRate
			,ChurnRate_Last60Days_Through_360Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 5 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast60Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast60DaysRegistered60Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast60Days_Over_UU_Last60Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast60DaysRegistered60Days_Over_UU_FirstTxInLast60Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast60DaysRegistered60Days_Over_UU_Last60Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,720 AllRange
			,60 CurrentRange
			,660 PreviousRange
			,UU_Last60Days UU_CurrentRange
			,UU_Retained_Last60Days_Through_720Days + UU_Churned_Last60Days_Through_720Days						  UU_PreviousRange
			,UU_NewContributer_Last60Days_To_720Days															  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last60Days_Through_720Days																  UU_Retained
			,UU_Churned_Last60Days_Through_720Days																  UU_Churned
			,RetentionRate_Last60Days_Through_720Days															  RetentionRate
			,ChurnRate_Last60Days_Through_720Days																  ChurnRate
		FROM RawData_CTE


		UNION ALL
		SELECT
			 6 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast90Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast90DaysRegistered90Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast90Days_Over_UU_Last90Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast90DaysRegistered90Days_Over_UU_FirstTxInLast90Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast90DaysRegistered90Days_Over_UU_Last90Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,1 RangesAreSymmetric
			,180 AllRange
			,90 CurrentRange
			,90 PreviousRange
			,UU_Last90Days UU_CurrentRange
			,UU_Retained_Last90Days_Through_180Days + UU_Churned_Last90Days_Through_180Days							  UU_PreviousRange
			,UU_NewContributer_Last90Days_To_180Days																  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last90Days_Through_180Days																	  UU_Retained
			,UU_Churned_Last90Days_Through_180Days																	  UU_Churned
			,RetentionRate_Last90Days_Through_180Days																  RetentionRate
			,ChurnRate_Last90Days_Through_180Days																	  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 6 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast90Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast90DaysRegistered90Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast90Days_Over_UU_Last90Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast90DaysRegistered90Days_Over_UU_FirstTxInLast90Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast90DaysRegistered90Days_Over_UU_Last90Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,360 AllRange
			,90 CurrentRange
			,270 PreviousRange
			,UU_Last90Days UU_CurrentRange
			,UU_Retained_Last90Days_Through_360Days + UU_Churned_Last90Days_Through_360Days						  UU_PreviousRange
			,UU_NewContributer_Last90Days_To_360Days															  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last90Days_Through_360Days																  UU_Retained
			,UU_Churned_Last90Days_Through_360Days																  UU_Churned
			,RetentionRate_Last90Days_Through_360Days															  RetentionRate
			,ChurnRate_Last90Days_Through_360Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 6 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast90Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast90DaysRegistered90Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast90Days_Over_UU_Last90Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast90DaysRegistered90Days_Over_UU_FirstTxInLast90Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast90DaysRegistered90Days_Over_UU_Last90Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,720 AllRange
			,90 CurrentRange
			,630 PreviousRange
			,UU_Last90Days UU_CurrentRange
			,UU_Retained_Last90Days_Through_720Days + UU_Churned_Last90Days_Through_720Days						  UU_PreviousRange
			,UU_NewContributer_Last90Days_To_720Days															  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last90Days_Through_720Days																  UU_Retained
			,UU_Churned_Last90Days_Through_720Days																  UU_Churned
			,RetentionRate_Last90Days_Through_720Days															  RetentionRate
			,ChurnRate_Last90Days_Through_720Days																  ChurnRate
		FROM RawData_CTE


		UNION ALL
		SELECT
			 7 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast180Days															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast180DaysRegistered180Days											UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast180Days_Over_UU_Last180Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast180DaysRegistered180Days_Over_UU_FirstTxInLast180Days		RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast180DaysRegistered180Days_Over_UU_Last180Days				RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,1 RangesAreSymmetric
			,360 AllRange
			,180 CurrentRange
			,180 PreviousRange
			,UU_Last180Days UU_CurrentRange
			,UU_Retained_Last180Days_Through_360Days + UU_Churned_Last180Days_Through_360Days					  UU_PreviousRange
			,UU_NewContributer_Last180Days_To_360Days															  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last180Days_Through_360Days															  UU_Retained
			,UU_Churned_Last180Days_Through_360Days																  UU_Churned
			,RetentionRate_Last180Days_Through_360Days															  RetentionRate
			,ChurnRate_Last180Days_Through_360Days																  ChurnRate
		FROM RawData_CTE
		UNION ALL
		SELECT
			 7 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast180Days															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast180DaysRegistered180Days											UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast180Days_Over_UU_Last180Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast180DaysRegistered180Days_Over_UU_FirstTxInLast180Days		RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast180DaysRegistered180Days_Over_UU_Last180Days				RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,0 RangesAreSymmetric
			,720 AllRange
			,180 CurrentRange
			,540 PreviousRange
			,UU_Last180Days UU_CurrentRange
			,UU_Retained_Last180Days_Through_720Days + UU_Churned_Last180Days_Through_720Days					  UU_PreviousRange
			,UU_NewContributer_Last180Days_To_720Days															  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last180Days_Through_720Days															  UU_Retained
			,UU_Churned_Last180Days_Through_720Days																  UU_Churned
			,RetentionRate_Last180Days_Through_720Days															  RetentionRate
			,ChurnRate_Last180Days_Through_720Days																  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT
			 8 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast360Days																UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast360DaysRegistered360Days												UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast360Days_Over_UU_Last360Days										RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast360DaysRegistered360Days_Over_UU_FirstTxInLast360Days			RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast360DaysRegistered360Days_Over_UU_Last360Days					RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,1 RangesAreSymmetric
			,720 AllRange
			,360 CurrentRange
			,360 PreviousRange
			,UU_Last360Days UU_CurrentRange
			,UU_Retained_Last360Days_Through_720Days + UU_Churned_Last360Days_Through_720Days					  UU_PreviousRange
			,UU_NewContributer_Last360Days_To_720Days															  UU_NewContributer_To_AllRange_In_CurrentRange
			,UU_Retained_Last360Days_Through_720Days															  UU_Retained
			,UU_Churned_Last360Days_Through_720Days																  UU_Churned
			,RetentionRate_Last360Days_Through_720Days															  RetentionRate
			,ChurnRate_Last360Days_Through_720Days																  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT
			 9 MeasureRangeType
			,1 HasDynamicBeginDate
			,UU_FirstTxInLast720Days															UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxInLast720DaysRegistered720Days											UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxInLast720Days_Over_UU_Last720Days									RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxInLast720DaysRegistered720Days_Over_UU_FirstTxInLast720Days		RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxInLast720DaysRegistered720Days_Over_UU_Last720Days				RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,NULL RangesAreSymmetric
			,NULL AllRange
			,NULL CurrentRange
			,NULL PreviousRange
			,UU_Last720Days UU_CurrentRange
			,NULL				  UU_PreviousRange
			,NULL				  UU_NewContributer_To_AllRange_In_CurrentRange
			,NULL				  UU_Retained
			,NULL				  UU_Churned
			,NULL				  RetentionRate
			,NULL				  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT

			 10 MeasureRangeType
			,0 HasDynamicBeginDate
			,UU_FirstTxWTDRegisteredWTD									UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxWTDRegisteredWTD									UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxWTD_Over_UUWTD							RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxWTDRegisteredWTD_Over_UU_FirstTxWTD		RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxWTDRegisteredWTD_Over_UUWTD				RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,NULL RangesAreSymmetric
			,NULL AllRange
			,NULL CurrentRange
			,NULL PreviousRange
			,UUWTD UU_CurrentRange
			,NULL				  UU_PreviousRange
			,NULL				  UU_NewContributer_To_AllRange_In_CurrentRange
			,NULL				  UU_Retained
			,NULL				  UU_Churned
			,NULL				  RetentionRate
			,NULL				  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT

			 11 MeasureRangeType
			,0 HasDynamicBeginDate
			,UU_FirstTxWTDRegisteredWTD									UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxWTDRegisteredWTD									UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTx2WTD_Over_UU2WTD							RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTx2WTDRegistered2WTD_Over_UU_FirstTx2WTD		RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTx2WTDRegistered2WTD_Over_UU2WTD				RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,NULL RangesAreSymmetric
			,NULL AllRange
			,NULL CurrentRange
			,NULL PreviousRange
			,UU2WTD UU_CurrentRange
			,NULL				  UU_PreviousRange
			,NULL				  UU_NewContributer_To_AllRange_In_CurrentRange
			,NULL				  UU_Retained
			,NULL				  UU_Churned
			,NULL				  RetentionRate
			,NULL				  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT
			 12 MeasureRangeType
			,0 HasDynamicBeginDate
			,UU_FirstTxMTDRegisteredMTD									UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxMTDRegisteredMTD									UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxMTD_Over_UUMTD							RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxMTDRegisteredMTD_Over_UU_FirstTxMTD		RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxMTDRegisteredMTD_Over_UUMTD				RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,NULL RangesAreSymmetric
			,NULL AllRange
			,NULL CurrentRange
			,NULL PreviousRange
			,UUMTD UU_CurrentRange
			,NULL				  UU_PreviousRange
			,NULL				  UU_NewContributer_To_AllRange_In_CurrentRange
			,NULL				  UU_Retained
			,NULL				  UU_Churned
			,NULL				  RetentionRate
			,NULL				  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT
			 13 MeasureRangeType
			,0 HasDynamicBeginDate
			,UU_FirstTxMTDRegisteredMTD									UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxMTDRegisteredMTD									UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTx2MTD_Over_UU2MTD							RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTx2MTDRegistered2MTD_Over_UU_FirstTx2MTD		RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTx2MTDRegistered2MTD_Over_UU2MTD				RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,NULL RangesAreSymmetric
			,NULL AllRange
			,NULL CurrentRange
			,NULL PreviousRange
			,UU2MTD UU_CurrentRange
			,NULL				  UU_PreviousRange
			,NULL				  UU_NewContributer_To_AllRange_In_CurrentRange
			,NULL				  UU_Retained
			,NULL				  UU_Churned
			,NULL				  RetentionRate
			,NULL				  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT
			 14 MeasureRangeType
			,0 HasDynamicBeginDate
			,UU_FirstTxQTDRegisteredQTD									UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxQTDRegisteredQTD									UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxQTD_Over_UUQTD							RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxQTDRegisteredQTD_Over_UU_FirstTxQTD		RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxQTDRegisteredQTD_Over_UUQTD				RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,NULL RangesAreSymmetric
			,NULL AllRange
			,NULL CurrentRange
			,NULL PreviousRange
			,UUQTD UU_CurrentRange
			,NULL				  UU_PreviousRange
			,NULL				  UU_NewContributer_To_AllRange_In_CurrentRange
			,NULL				  UU_Retained
			,NULL				  UU_Churned
			,NULL				  RetentionRate
			,NULL				  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT
			 15 MeasureRangeType
			,0 HasDynamicBeginDate
			,UU_FirstTxSemiYTDRegisteredSemiYTD									UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxSemiYTDRegisteredSemiYTD									UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxSemiYTD_Over_UUSemiYTD							RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxSemiYTDRegisteredSemiYTD_Over_UU_FirstTxSemiYTD		RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxSemiYTDRegisteredSemiYTD_Over_UUSemiYTD				RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,NULL RangesAreSymmetric
			,NULL AllRange
			,NULL CurrentRange
			,NULL PreviousRange
			,UUSemiYTD UU_CurrentRange
			,NULL				  UU_PreviousRange
			,NULL				  UU_NewContributer_To_AllRange_In_CurrentRange
			,NULL				  UU_Retained
			,NULL				  UU_Churned
			,NULL				  RetentionRate
			,NULL				  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT
			 15 MeasureRangeType
			,0 HasDynamicBeginDate
			,UU_FirstTxYTDRegisteredYTD									UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTxYTDRegisteredYTD									UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTxYTD_Over_UUYTD							RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTxYTDRegisteredYTD_Over_UU_FirstTxYTD		RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTxYTDRegisteredYTD_Over_UUYTD				RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,NULL RangesAreSymmetric
			,NULL AllRange
			,NULL CurrentRange
			,NULL PreviousRange
			,UUYTD UU_CurrentRange
			,NULL				  UU_PreviousRange
			,NULL				  UU_NewContributer_To_AllRange_In_CurrentRange
			,NULL				  UU_Retained
			,NULL				  UU_Churned
			,NULL				  RetentionRate
			,NULL				  ChurnRate
		FROM RawData_CTE

		UNION ALL
		SELECT
			 15 MeasureRangeType
			,0 HasDynamicBeginDate
			,UU_FirstTx2YTDRegistered2YTD								UU_FirstTransactions_AnyRegisterDate
			,UU_FirstTx2YTDRegistered2YTD								UU_FirstTransactions_RegisteredInRange
			,RateOf_UU_FirstTx2YTD_Over_UU2YTD							RateOf_UU_FirstTransactions_AnyRegisterDate_Over_Range
			,RateOf_UU_FirstTx2YTDRegistered2YTD_Over_UU_FirstTx2YTD	RateOf_UU_FirstTransactions_RegisteredInRange_Over_RegisteredAnyTime
			,RateOf_UU_FirstTx2YTDRegistered2YTD_Over_UU2YTD			RateOf_UU_FirstTransactions_RegisteredInRange_Over_Range
			,NULL RangesAreSymmetric
			,NULL AllRange
			,NULL CurrentRange
			,NULL PreviousRange
			,UU2YTD UU_CurrentRange
			,NULL				  UU_PreviousRange
			,NULL				  UU_NewContributer_To_AllRange_In_CurrentRange
			,NULL				  UU_Retained
			,NULL				  UU_Churned
			,NULL				  RetentionRate
			,NULL				  ChurnRate
		FROM RawData_CTE
		)
		INSERT INTO DWH_ManipulatedTables.DBO.FACT_BI_UserEngagementPeriodsWithChurnRetention
		SELECT
			 @DailySP [Date]
			,@_FeatureType FeatureType
			,IIF(@_CardTransactionType = -1,NULL,@_CardTransactionType) CardTransactionType
			,case when @_X1=0 and @_Y1=1		  THEN NULL
				  when @_X1=1 and @_Y1=0		  THEN NULL
				  when @_X1=1 and @_Y1 IN(-1,-2)  THEN 1
				  when @_X1=1 and @_Y1 =1		  THEN 1
				  when @_X1 IN(-1,-2) and @_Y1 =1 THEN 1
				  when @_X1=0 and @_Y1 IN(-1,-2)  THEN 0
				  when @_X1 IN(-1,-2) and @_Y1 =0 THEN 0
				  when @_X1=0 and @_Y1 =0		  THEN 0
			 END Is_Offline
			,case when @_X2=0 and @_Y2=1		  THEN NULL
				  when @_X2=1 and @_Y2=0		  THEN NULL
				  when @_X2=1 and @_Y2 IN(-1,-2)  THEN 1
				  when @_X2=1 and @_Y2 =1		  THEN 1
				  when @_X2 IN(-1,-2) and @_Y2 =1 THEN 1
				  when @_X2=0 and @_Y2 IN(-1,-2)  THEN 0
				  when @_X2 IN(-1,-2) and @_Y2 =0 THEN 0
				  when @_X2=0 and @_Y2 =0		  THEN 0
			 END Is_Abroad
		    ,case when @_ConditionIdNullity = 0   THEN 1
		 		  when @_ConditionIdNullity = 1   THEN 0
			 ELSE NULL
			 END ConditionIdIsNull
			 ,*
			 ,CAST(
			 	   CASE WHEN ChurnRate >= 0	   AND ChurnRate < 0.05 THEN 0 -- Very Low Churn (0%-5%)
			 	  	    WHEN ChurnRate >= 0.05 AND ChurnRate < 0.2  THEN 1 -- Low Churn [5%-20%)
			 	  	    WHEN ChurnRate >= 0.2  AND ChurnRate < 0.35 THEN 2 -- Moderate Churn [20%-35%)
			 	  	    WHEN ChurnRate >= 0.35 AND ChurnRate < 0.5  THEN 3 -- High Churn [35%-50%)
			 	  	    WHEN ChurnRate >= 0.5  AND ChurnRate < 0.6  THEN 4 -- Very High Churn [50%-60%)
			 	  	    WHEN ChurnRate >= 0.6  AND ChurnRate < 0.7  THEN 5 -- Alarmingly High Churn [60%-70%)
			 	  	    WHEN ChurnRate >= 0.7  AND ChurnRate < 0.8  THEN 6 -- Critical Churn [70%-80%)
			 	  	    WHEN ChurnRate >= 0.8  AND ChurnRate < 0.95 THEN 7 -- Disastrous Churn [80%-95%)
			 	  	    WHEN ChurnRate >= 0.95 AND ChurnRate <= 1   THEN 8 -- Collapse-Level Churn  [95%-100%)
			 	   END
			  AS TINYINT) ChurnLevelType
		FROM EngagingDataWith_ChurnComment
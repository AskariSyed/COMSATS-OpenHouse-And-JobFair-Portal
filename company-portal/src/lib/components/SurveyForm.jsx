import React, { useState, useEffect } from 'react';
import { Loader2, AlertCircle, CheckCircle, ClipboardList, GraduationCap, Building2 } from 'lucide-react';
import { getSurveyTemplate, submitBothSurveys, getMySurveyStatus } from '../api';

const LIKERT_SCALE = [
  { value: 'Exceptionally', label: 'Exceptionally', color: 'bg-green-500' },
  { value: 'ToAGreatExtent', label: 'To a Great Extent', color: 'bg-green-400' },
  { value: 'Moderately', label: 'Moderately', color: 'bg-yellow-400' },
  { value: 'Somewhat', label: 'Somewhat', color: 'bg-orange-400' },
  { value: 'NotAtAll', label: 'Not at All', color: 'bg-red-400' }
];

const RATING_OPTIONS = [
  { value: 'Good', label: 'Good', color: 'bg-green-100 text-green-900 border-green-300' },
  { value: 'Average', label: 'Average', color: 'bg-yellow-100 text-yellow-900 border-yellow-300' },
  { value: 'Bad', label: 'Bad', color: 'bg-red-100 text-red-900 border-red-300' }
];

const PEO_COLORS = {
  peO1: 'border-l-4 border-l-blue-500 bg-blue-50',
  peO2: 'border-l-4 border-l-purple-500 bg-purple-50',
  peO3: 'border-l-4 border-l-pink-500 bg-pink-50',
  peO4: 'border-l-4 border-l-green-500 bg-green-50'
};

const getPEOTitle = (peoKey) => {
  const titles = {
    peO1: 'PEO 1: Technical Knowledge & Problem Solving',
    peO2: 'PEO 2: Learning & Entrepreneurship',
    peO3: 'PEO 3: Ethics & Communication',
    peO4: 'PEO 4: Societal & Economic Contribution'
  };
  return titles[peoKey] || peoKey;
};

export default function SurveyForm({ onError, onSuccess, forceDisabled = false }) {
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [templates, setTemplates] = useState({});
  const [submitted, setSubmitted] = useState({ cdc: false, department: false });
  const [hasActiveJobFair, setHasActiveJobFair] = useState(true);
  const [isJobFairDay, setIsJobFairDay] = useState(false);

  // CDC Survey State
  const [cdcResponses, setCdcResponses] = useState({
    fypQuality: '',
    fypComments: '',
    arrangementQuality: '',
    arrangementComments: '',
    lunchQuality: '',
    lunchComments: ''
  });

  // Comments visibility state
  const [commentsVisible, setCommentsVisible] = useState({
    fyp: false,
    arrangement: false,
    lunch: false
  });

  // Department Survey State
  const [departmentResponses, setDepartmentResponses] = useState({
    peO1: {},
    peO2: {},
    peO3: {},
    peO4: {},
    technologiesSuggestion: '',
    generalFeedback: '',
    improvementSuggestions: ''
  });

  useEffect(() => {
    fetchSurveyData();
  }, []);

  const fetchSurveyData = async () => {
    setLoading(true);
    try {
      const [cdcTemplate, deptTemplate, surveyStatus] = await Promise.all([
        getSurveyTemplate('CDC'),
        getSurveyTemplate('Department'),
        getMySurveyStatus()
      ]);

      setTemplates({
        cdc: cdcTemplate,
        department: deptTemplate
      });

      const submittedData = surveyStatus?.submitted || surveyStatus?.Submitted || {};
      setSubmitted({
        cdc: Boolean(submittedData.cdc ?? submittedData.Cdc),
        department: Boolean(submittedData.department ?? submittedData.Department)
      });
      setHasActiveJobFair(Boolean(surveyStatus?.hasActiveJobFair ?? surveyStatus?.HasActiveJobFair ?? true));
      setIsJobFairDay(Boolean(surveyStatus?.isJobFairDay ?? surveyStatus?.IsJobFairDay ?? false));
    } catch (err) {
      onError(`Failed to load survey templates: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const getDepartmentQuestionCount = () => {
    if (!templates.department?.peOs) return 0;
    return Object.values(templates.department.peOs).reduce((total, questions) => total + questions.length, 0);
  };

  const getAnsweredDepartmentCount = () => {
    if (!templates.department?.peOs) return 0;
    return Object.entries(templates.department.peOs).reduce((total, [peoKey, questions]) => {
      const answered = questions.filter((_, idx) => Boolean(departmentResponses[peoKey]?.[idx])).length;
      return total + answered;
    }, 0);
  };

  const getOpenEndedCount = () => templates.department?.openEnded?.length || 0;

  const getAnsweredOpenEndedCount = () => {
    return [
      departmentResponses.technologiesSuggestion,
      departmentResponses.generalFeedback,
      departmentResponses.improvementSuggestions
    ].filter((value) => value?.trim()).length;
  };

  const getDepartmentPayload = () => ({
    PEO1_Q1: departmentResponses.peO1?.[0],
    PEO1_Q2: departmentResponses.peO1?.[1],
    PEO1_Q3: departmentResponses.peO1?.[2],
    PEO2_Q1: departmentResponses.peO2?.[0],
    PEO2_Q2: departmentResponses.peO2?.[1],
    PEO3_Q1: departmentResponses.peO3?.[0],
    PEO3_Q2: departmentResponses.peO3?.[1],
    PEO4_Q1: departmentResponses.peO4?.[0],
    PEO4_Q2: departmentResponses.peO4?.[1],
    PEO4_Q3: departmentResponses.peO4?.[2],
    technologiesSuggestion: departmentResponses.technologiesSuggestion || '',
    generalFeedback: departmentResponses.generalFeedback || '',
    improvementSuggestions: departmentResponses.improvementSuggestions || ''
  });

  const totalRequiredQuestions = 3 + getDepartmentQuestionCount() + getOpenEndedCount();
  const answeredRequiredQuestions =
    [cdcResponses.fypQuality, cdcResponses.arrangementQuality, cdcResponses.lunchQuality].filter(Boolean).length +
    getAnsweredDepartmentCount() +
    getAnsweredOpenEndedCount();
  const progressPercentage = totalRequiredQuestions > 0
    ? Math.round((answeredRequiredQuestions / totalRequiredQuestions) * 100)
    : 0;
  const isSurveyComplete = totalRequiredQuestions > 0 && answeredRequiredQuestions === totalRequiredQuestions;

  const handleSubmitAll = async () => {
    if (!isSurveyComplete) {
      onError('Please complete all required survey questions before submitting.');
      return;
    }

    setSubmitting(true);
    try {
      const result = await submitBothSurveys({
        cdcResponse: {
          fypQuality: cdcResponses.fypQuality,
          fypComments: cdcResponses.fypComments || '',
          arrangementQuality: cdcResponses.arrangementQuality,
          arrangementComments: cdcResponses.arrangementComments || '',
          lunchQuality: cdcResponses.lunchQuality,
          lunchComments: cdcResponses.lunchComments || ''
        },
        departmentResponse: getDepartmentPayload()
      });

      const created = result?.created || result?.Created || [];
      const skipped = result?.skipped || result?.Skipped || [];
      const processedTypes = [...created, ...skipped].map((item) => (item?.type || item?.Type || '').toLowerCase());

      setSubmitted({
        cdc: submitted.cdc || processedTypes.includes('cdc'),
        department: submitted.department || processedTypes.includes('department')
      });

      if (onSuccess) onSuccess('✓ Survey submitted successfully!');
    } catch (err) {
      onError(`Failed to submit survey: ${err.message}`);
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return <div className="text-center py-12"><Loader2 className="animate-spin mx-auto text-blue-600 w-10 h-10" /></div>;
  }

  return (
    <div className="space-y-4 pb-24">
      {/* Header */}
      <div>
        <h2 className="text-xl font-bold text-gray-900">Job Fair Feedback</h2>
        <p className="text-gray-500 text-sm">Your feedback helps us improve future events</p>
      </div>

      {!hasActiveJobFair && (
        <div className="flex items-center gap-2 p-3 bg-yellow-50 text-yellow-800 rounded border border-yellow-200">
          <AlertCircle className="w-4 h-4" />
          <span className="text-sm font-medium">No active job fair right now. Survey is not available.</span>
        </div>
      )}

      {hasActiveJobFair && (!isJobFairDay || forceDisabled) && (
        <div className="flex items-center gap-2 p-3 bg-yellow-50 text-yellow-800 rounded border border-yellow-200">
          <AlertCircle className="w-4 h-4" />
          <span className="text-sm font-medium">Survey is available only on job fair day.</span>
        </div>
      )}

      {hasActiveJobFair && isJobFairDay && !forceDisabled && submitted.cdc && submitted.department && (
        <div className="flex items-center gap-2 p-3 bg-green-50 text-green-700 rounded border border-green-200">
          <CheckCircle className="w-4 h-4" />
          <span className="text-sm font-medium">You have already submitted both surveys for this job fair.</span>
        </div>
      )}

      {hasActiveJobFair && isJobFairDay && !forceDisabled && !(submitted.cdc && submitted.department) && (
      <>
      {/* CDC Survey */}
      <div className="bg-white border border-gray-200 rounded-lg p-3 space-y-2">
        <h3 className="text-lg font-bold text-gray-900 border-b border-gray-200 pb-1 flex items-center justify-center gap-2 text-center">
          <ClipboardList className="w-5 h-5 text-blue-600" /> CDC Survey
        </h3>
        {submitted.cdc ? (
          <div className="flex items-center gap-2 p-2 bg-green-50 text-green-700 rounded border border-green-200">
            <CheckCircle className="w-4 h-4" />
            <span className="text-sm font-medium">You have already submitted the CDC survey.</span>
          </div>
        ) : (
          <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {/* FYP Quality */}
                <div className="bg-white border border-gray-200 rounded p-2 space-y-1.5 text-center">
                  <h4 className="font-medium text-gray-900 text-sm flex items-center justify-center gap-1.5">
                    <GraduationCap className="w-4 h-4 text-blue-600" /> FYP Quality
                  </h4>
                  <div className="flex gap-2 flex-wrap justify-center">
                    {RATING_OPTIONS.map((option) => (
                      <label key={`fyp-${option.value}`} className="cursor-pointer">
                        <input
                          type="radio"
                          name="fypQuality"
                          value={option.value}
                          checked={cdcResponses.fypQuality === option.value}
                          onChange={(e) => setCdcResponses({ ...cdcResponses, fypQuality: e.target.value })}
                          className="sr-only"
                        />
                        <span className={`px-3 py-1 rounded text-xs font-medium border transition-all cursor-pointer ${
                          option.color
                        } ${
                          cdcResponses.fypQuality === option.value
                            ? 'ring-2 ring-offset-1 ring-gray-400 shadow-sm'
                            : 'hover:shadow-sm'
                        }`}>
                          {option.label}
                        </span>
                      </label>
                    ))}
                  </div>
                  {commentsVisible.fyp ? (
                    <div className="space-y-1.5">
                      <textarea
                        placeholder="Optional comments..."
                        rows="2"
                        value={cdcResponses.fypComments}
                        onChange={(e) => setCdcResponses({ ...cdcResponses, fypComments: e.target.value })}
                        className="w-full border border-gray-300 rounded p-2 text-sm resize-none focus:ring-1 focus:ring-blue-500 focus:border-transparent text-left"
                      />
                      <button
                        type="button"
                        onClick={() => setCommentsVisible({ ...commentsVisible, fyp: false })}
                        className="text-xs text-gray-500 hover:text-gray-700 underline mx-auto"
                      >
                        Hide comments
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      onClick={() => setCommentsVisible({ ...commentsVisible, fyp: true })}
                      className="px-3 py-1 text-xs bg-gray-100 hover:bg-gray-200 text-gray-700 rounded border border-gray-300 transition-colors mx-auto"
                    >
                      Add comments (optional)
                    </button>
                  )}
                </div>

                {/* Arrangement Quality */}
                <div className="bg-white border border-gray-200 rounded p-2 space-y-1.5 text-center">
                  <h4 className="font-medium text-gray-900 text-sm flex items-center justify-center gap-1.5">
                    <Building2 className="w-4 h-4 text-blue-600" /> Arrangement Quality
                  </h4>
                  <div className="flex gap-2 flex-wrap justify-center">
                    {RATING_OPTIONS.map((option) => (
                      <label key={`arrangement-${option.value}`} className="cursor-pointer">
                        <input
                          type="radio"
                          name="arrangementQuality"
                          value={option.value}
                          checked={cdcResponses.arrangementQuality === option.value}
                          onChange={(e) => setCdcResponses({ ...cdcResponses, arrangementQuality: e.target.value })}
                          className="sr-only"
                        />
                        <span className={`px-3 py-1 rounded text-xs font-medium border transition-all cursor-pointer ${
                          option.color
                        } ${
                          cdcResponses.arrangementQuality === option.value
                            ? 'ring-2 ring-offset-1 ring-gray-400 shadow-sm'
                            : 'hover:shadow-sm'
                        }`}>
                          {option.label}
                        </span>
                      </label>
                    ))}
                  </div>
                  {commentsVisible.arrangement ? (
                    <div className="space-y-1.5">
                      <textarea
                        placeholder="Optional comments..."
                        rows="2"
                        value={cdcResponses.arrangementComments}
                        onChange={(e) => setCdcResponses({ ...cdcResponses, arrangementComments: e.target.value })}
                        className="w-full border border-gray-300 rounded p-2 text-sm resize-none focus:ring-1 focus:ring-blue-500 focus:border-transparent text-left"
                      />
                      <button
                        type="button"
                        onClick={() => setCommentsVisible({ ...commentsVisible, arrangement: false })}
                        className="text-xs text-gray-500 hover:text-gray-700 underline mx-auto"
                      >
                        Hide comments
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      onClick={() => setCommentsVisible({ ...commentsVisible, arrangement: true })}
                      className="px-3 py-1 text-xs bg-gray-100 hover:bg-gray-200 text-gray-700 rounded border border-gray-300 transition-colors mx-auto"
                    >
                      Add comments (optional)
                    </button>
                  )}
                </div>

                {/* Lunch Quality */}
                <div className="bg-white border border-gray-200 rounded p-2 space-y-1.5 text-center">
                  <h4 className="font-medium text-gray-900 text-sm flex items-center justify-center gap-1.5">
                    <CheckCircle className="w-4 h-4 text-blue-600" /> Lunch Quality
                  </h4>
                  <div className="flex gap-2 flex-wrap justify-center">
                    {RATING_OPTIONS.map((option) => (
                      <label key={`lunch-${option.value}`} className="cursor-pointer">
                        <input
                          type="radio"
                          name="lunchQuality"
                          value={option.value}
                          checked={cdcResponses.lunchQuality === option.value}
                          onChange={(e) => setCdcResponses({ ...cdcResponses, lunchQuality: e.target.value })}
                          className="sr-only"
                        />
                        <span className={`px-3 py-1 rounded text-xs font-medium border transition-all cursor-pointer ${
                          option.color
                        } ${
                          cdcResponses.lunchQuality === option.value
                            ? 'ring-2 ring-offset-1 ring-gray-400 shadow-sm'
                            : 'hover:shadow-sm'
                        }`}>
                          {option.label}
                        </span>
                      </label>
                    ))}
                  </div>
                  {commentsVisible.lunch ? (
                    <div className="space-y-1.5">
                      <textarea
                        placeholder="Optional comments..."
                        rows="2"
                        value={cdcResponses.lunchComments}
                        onChange={(e) => setCdcResponses({ ...cdcResponses, lunchComments: e.target.value })}
                        className="w-full border border-gray-300 rounded p-2 text-sm resize-none focus:ring-1 focus:ring-blue-500 focus:border-transparent text-left"
                      />
                      <button
                        type="button"
                        onClick={() => setCommentsVisible({ ...commentsVisible, lunch: false })}
                        className="text-xs text-gray-500 hover:text-gray-700 underline mx-auto"
                      >
                        Hide comments
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      onClick={() => setCommentsVisible({ ...commentsVisible, lunch: true })}
                      className="px-3 py-1 text-xs bg-gray-100 hover:bg-gray-200 text-gray-700 rounded border border-gray-300 transition-colors mx-auto"
                    >
                      Add comments (optional)
                    </button>
                  )}
                </div>
              </div>

            </div>
          )}
        </div>

      {/* Department Survey */}
      <div className="bg-white border border-gray-200 rounded-lg p-3 space-y-3">
        <h3 className="text-lg font-bold text-gray-900 border-b border-gray-200 pb-1">Department Survey</h3>
        {submitted.department ? (
          <div className="flex items-center gap-2 p-2 bg-green-50 text-green-700 rounded border border-green-200">
            <CheckCircle className="w-4 h-4" />
            <span className="text-sm font-medium">You have already submitted the Department survey.</span>
          </div>
        ) : (
          <div className="space-y-3">
              {/* PEO Questions */}
              {templates.department?.peOs && Object.keys(templates.department.peOs).map((peoKey) => (
                <div key={peoKey} className={`space-y-2 p-2 rounded ${PEO_COLORS[peoKey]}`}>
                  <h3 className="font-semibold text-sm text-gray-900">{getPEOTitle(peoKey)}</h3>
                  {templates.department.peOs[peoKey].map((question, idx) => (
                    <div key={idx} className="space-y-1.5 bg-white p-2 rounded border border-gray-100">
                      <p className="text-sm font-medium text-gray-800">{question}</p>
                      <div className="grid grid-cols-2 md:grid-cols-5 gap-1">
                        {LIKERT_SCALE.map((scale) => (
                          <label key={scale.value} className="flex flex-col items-center gap-1 cursor-pointer group">
                            <input
                              type="radio"
                              name={`${peoKey}-${idx}`}
                              value={scale.value}
                              checked={departmentResponses[peoKey]?.[idx] === scale.value}
                              onChange={(e) => {
                                setDepartmentResponses({
                                  ...departmentResponses,
                                  [peoKey]: {
                                    ...departmentResponses[peoKey],
                                    [idx]: e.target.value
                                  }
                                });
                              }}
                              className="w-3 h-3 cursor-pointer"
                            />
                            <span className={`text-xs font-medium text-center leading-tight px-1 py-1 rounded ${scale.color} text-white transition-all ${departmentResponses[peoKey]?.[idx] === scale.value ? 'ring-1 ring-offset-1 ring-gray-400' : ''}`}>
                              {scale.label}
                            </span>
                          </label>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              ))}

              {/* Open-Ended Questions */}
              {templates.department?.openEnded && (
                <div className="space-y-2 p-2 bg-gradient-to-br from-indigo-50 to-blue-50 rounded border border-indigo-200">
                  <h3 className="font-semibold text-sm text-indigo-900">Additional Feedback & Suggestions</h3>
                  {templates.department.openEnded.map((question, idx) => (
                    <div key={idx} className="space-y-1.5 bg-white p-2 rounded border border-indigo-100">
                      <label className="text-sm font-medium text-gray-800">{question}</label>
                      <textarea
                        placeholder="Share your thoughts here..."
                        rows="2"
                        value={
                          idx === 0 ? departmentResponses.technologiesSuggestion :
                          idx === 1 ? departmentResponses.generalFeedback :
                          departmentResponses.improvementSuggestions
                        }
                        onChange={(e) => {
                          if (idx === 0) setDepartmentResponses({ ...departmentResponses, technologiesSuggestion: e.target.value });
                          else if (idx === 1) setDepartmentResponses({ ...departmentResponses, generalFeedback: e.target.value });
                          else setDepartmentResponses({ ...departmentResponses, improvementSuggestions: e.target.value });
                        }}
                        className="w-full border border-indigo-200 rounded p-2 text-sm resize-none focus:ring-1 focus:ring-indigo-500 focus:border-transparent"
                      />
                    </div>
                  ))}
                </div>
              )}

            </div>
          )}
        </div>
      </>
      )}

      {hasActiveJobFair && !(submitted.cdc && submitted.department) && (
        <div className="sticky bottom-3 z-30">
          <div className="bg-white/95 backdrop-blur border border-gray-200 rounded-lg shadow-sm p-3">
            {!isSurveyComplete ? (
              <>
                <div className="flex items-center justify-between text-xs text-gray-600 mb-2">
                  <span>Survey Progress</span>
                  <span>{answeredRequiredQuestions}/{totalRequiredQuestions} answered ({progressPercentage}%)</span>
                </div>
                <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-blue-600 transition-all duration-300"
                    style={{ width: `${progressPercentage}%` }}
                  />
                </div>
              </>
            ) : (
              <button
                type="button"
                disabled={submitting}
                onClick={handleSubmitAll}
                className="w-full px-4 py-2 bg-blue-600 text-white font-semibold rounded hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 text-sm"
              >
                {submitting ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Submitting...
                  </>
                ) : (
                  'Submit Complete Survey'
                )}
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

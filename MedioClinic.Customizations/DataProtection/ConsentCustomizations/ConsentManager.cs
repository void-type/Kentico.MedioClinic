﻿using System;
using System.Collections.Generic;
using System.Linq;

using CMS.ContactManagement;
using CMS.Core;
using CMS.DataEngine;
using CMS.DataProtection;
using CMS.Helpers;

using MedioClinic.Customizations.Cookies;

namespace MedioClinic.Customizations.DataProtection.Consent
{
    public class ConsentManager : IConsentManager
    {
        public const string ConsentIdColumnName = nameof(ConsentCookieLevelInfo.ConsentID);

        private readonly IConsentCookieLevelInfoProvider _consentCookieLevelInfoProvider;

        private readonly IConsentInfoProvider _consentInfoProvider;

        public ConsentManager(IConsentCookieLevelInfoProvider consentCookieLevelInfoProvider, IConsentInfoProvider consentInfoProvider)
        {
            _consentCookieLevelInfoProvider = consentCookieLevelInfoProvider ?? throw new ArgumentNullException(nameof(consentCookieLevelInfoProvider));
            _consentInfoProvider = consentInfoProvider ?? throw new ArgumentNullException(nameof(consentInfoProvider));
        }

        /// <summary>
        /// Handles the <see cref="DataProtectionEvents.RevokeConsentAgreement"/> event.
        /// </summary>
        /// <param name="sender">Sender.</param>
        /// <param name="args">Event arguments.</param>
        public static void RevokeConsentAgreementHandler(object sender, EventArgs args)
        {
            var currentCookieLevelProvider = Service.Resolve<ICurrentCookieLevelProvider>();
            var consentCookieLevelInfoProvider = Service.Resolve<IConsentCookieLevelInfoProvider>();
            var currentCookieLevel = currentCookieLevelProvider.GetCurrentCookieLevel();
            var contact = ContactManagementContext.GetCurrentContact(false);
            int? smallerOrSameCookieLevel = default;

            if (contact != null)
            {
                var agreedConsentIds = GetAgreedConsentIds(contact);

                // Get the next-lower cookie level assigned to one of the agreed consents.
                smallerOrSameCookieLevel = consentCookieLevelInfoProvider.Get()
                    .WhereIn(ConsentIdColumnName, agreedConsentIds)
                    .WhereLessOrEquals(CookieManager.CookieLevelColumnName, currentCookieLevel)
                    .WhereGreaterThan(CookieManager.CookieLevelColumnName, CookieManager.NullIntegerValue)
                    .OrderBy(CookieManager.CookieLevelColumnName)
                    .TopN(1)
                    .FirstOrDefault()
                    ?.CookieLevel; 
            }

            currentCookieLevelProvider.SetCurrentCookieLevel(smallerOrSameCookieLevel ?? currentCookieLevelProvider.GetDefaultCookieLevel());
        }

        public ObjectQuery<ConsentInfo> GetAllConsentsWithSameOrLowerCookieLevel(int cookieLevel)
        {
            var consentCookieLevels = _consentCookieLevelInfoProvider.Get()
                .WhereLessOrEquals(CookieManager.CookieLevelColumnName, cookieLevel)
                .WhereGreaterThan(CookieManager.CookieLevelColumnName, CookieManager.NullIntegerValue);

            return _consentInfoProvider.Get()
                .WhereIn(ConsentIdColumnName, consentCookieLevels?.TypedResult?.Select(consentCookieLevel => consentCookieLevel.ConsentID).ToList());
        }

        public ObjectQuery<ConsentInfo> GetAgreedConsentsWithHigherCookieLevel(ContactInfo contact, int cookieLevel)
        {
            var agreedConsentIds = GetAgreedConsentIds(contact);

            var consentCookieLevels = _consentCookieLevelInfoProvider.Get()
                .WhereIn(ConsentIdColumnName, agreedConsentIds)
                .WhereGreaterThan(CookieManager.CookieLevelColumnName, cookieLevel);

            return _consentInfoProvider.Get()
                .WhereIn(ConsentIdColumnName, consentCookieLevels?.TypedResult?.Select(consentCookieLevel => consentCookieLevel.ConsentID).ToList());
        }

        private static List<int> GetAgreedConsentIds(ContactInfo contact) =>
            GetAgreedConsents(contact)?.Select(consent => consent.Id)?.ToList();

        private static IEnumerable<CMS.DataProtection.Consent> GetAgreedConsents(ContactInfo contact)
        {
            var consentAgreementService = Service.Resolve<IConsentAgreementService>();

            return consentAgreementService.GetAgreedConsents(contact);
        }
    }
}

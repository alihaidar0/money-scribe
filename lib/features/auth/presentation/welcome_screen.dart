import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/app_icon_image.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/linked_text.dart';

/// AUTH-1: the first screen of a signed-out person. It has no state and no
/// data, so it needs no Bloc: its buttons only open the next screen.
class WelcomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return FlowPage(
      showBackButton: false,
      centered: true,
      content: [
        const Align(child: AppIconImage()),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            l10n.appTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.welcomeTagline,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
      bottomChildren: [
        FilledButton(
          onPressed: () => context.push(AppRoutes.signIn),
          child: Text(l10n.signIn),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () => context.push(AppRoutes.register),
          child: Text(l10n.createAccount),
        ),
        const SizedBox(height: 16),
        // The Terms and the Privacy Policy are not written yet, so their
        // links do nothing for now.
        LinkedText(
          message: (links) =>
              l10n.welcomeAgreement(terms: links[0], privacy: links[1]),
          links: [TextLink(l10n.termsName), TextLink(l10n.privacyPolicyName)],
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
